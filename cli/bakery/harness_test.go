package main

import (
	"bytes"
	"encoding/base64"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"testing"
)

// The tests run the real bakery binary against a scratch checkout, with fake
// docker and grype executables on PATH that record how they were called.

var bakeryBin string

func TestMain(m *testing.M) {
	dir, err := os.MkdirTemp("", "bakery-bin")
	if err != nil {
		panic(err)
	}
	bakeryBin = filepath.Join(dir, "bakery")
	if runtime.GOOS == "windows" {
		bakeryBin += ".exe"
	}
	build := exec.Command("go", "build", "-o", bakeryBin, ".")
	build.Stdout, build.Stderr = os.Stdout, os.Stderr
	if err := build.Run(); err != nil {
		panic(err)
	}
	code := m.Run()
	_ = os.RemoveAll(dir)
	os.Exit(code)
}

const fakeDocker = `#!/bin/sh
{
  printf 'docker'
  for a in "$@"; do printf ' %s' "$a"; done
  printf '\n'
  for v in ACS_VERSION APS_VERSION ARTIFACT_VERSIONS REGISTRY REGISTRY_NAMESPACE TAG; do
    eval "isset=\${$v+x}"
    if [ -n "$isset" ]; then eval "printf '  %s=%s\n' $v \"\$$v\""; fi
  done
} >> "$FAKE_LOG"
case "$1 $2" in
  "buildx version") echo "github.com/docker/buildx v0.0.0-fake" ;;
  "login "*) exit "${FAKE_LOGIN_EXIT:-0}" ;;
esac
for a in "$@"; do
  if [ "$a" = "--print" ]; then cat "$FAKE_PRINT"; fi
done
exit 0
`

const fakeGrype = `#!/bin/sh
{
  printf 'grype'
  for a in "$@"; do printf ' %s' "$a"; done
  printf '\n  argv:'
  for a in "$@"; do printf ' [%s]' "$a"; done
  printf '\n'
} >> "$FAKE_LOG"
echo "report for $*"
`

type fixture struct {
	t     *testing.T
	root  string
	home  string
	bin   string
	log   string
	print string
	env   []string
}

func newFixture(t *testing.T) *fixture {
	t.Helper()
	if runtime.GOOS == "windows" {
		t.Skip("fake docker/grype are shell scripts")
	}
	base := t.TempDir()
	f := &fixture{
		t:     t,
		root:  filepath.Join(base, "repo"),
		home:  filepath.Join(base, "home"),
		bin:   filepath.Join(base, "bin"),
		log:   filepath.Join(base, "calls.log"),
		print: filepath.Join(base, "print.json"),
	}
	for _, d := range []string{f.root, f.home, f.bin} {
		must(t, os.MkdirAll(d, 0o755))
	}
	f.write("docker-bake.hcl", "")
	f.write("sources.yaml", "sources:\n  public:\n    url: http://127.0.0.1:1/public\n")
	must(t, os.WriteFile(filepath.Join(f.bin, "docker"), []byte(fakeDocker), 0o755))
	must(t, os.WriteFile(filepath.Join(f.bin, "grype"), []byte(fakeGrype), 0o755))
	must(t, os.WriteFile(f.print, []byte(`{"target":{}}`), 0o644))
	return f
}

func must(t *testing.T, err error) {
	t.Helper()
	if err != nil {
		t.Fatal(err)
	}
}

// write creates a file under the fixture root.
func (f *fixture) write(rel, content string) string {
	f.t.Helper()
	p := filepath.Join(f.root, rel)
	must(f.t, os.MkdirAll(filepath.Dir(p), 0o755))
	must(f.t, os.WriteFile(p, []byte(content), 0o644))
	return p
}

func (f *fixture) exists(rel string) bool {
	_, err := os.Stat(filepath.Join(f.root, rel))
	return err == nil
}

func (f *fixture) netrc(content string) {
	f.t.Helper()
	must(f.t, os.WriteFile(filepath.Join(f.home, ".netrc"), []byte(content), 0o600))
}

func (f *fixture) calls() string {
	b, err := os.ReadFile(f.log)
	if err != nil && !os.IsNotExist(err) {
		f.t.Fatal(err)
	}
	return string(b)
}

type result struct {
	out  string
	code int
}

// run executes bakery in the fixture root with a clean environment.
func (f *fixture) run(stdin string, args ...string) result {
	f.t.Helper()
	cmd := exec.Command(bakeryBin, args...)
	cmd.Dir = f.root
	cmd.Env = append([]string{
		"HOME=" + f.home,
		"PATH=" + f.bin + string(os.PathListSeparator) + "/usr/bin:/bin",
		"FAKE_LOG=" + f.log,
		"FAKE_PRINT=" + f.print,
	}, f.env...)
	cmd.Stdin = strings.NewReader(stdin)
	var out bytes.Buffer
	cmd.Stdout, cmd.Stderr = &out, &out
	err := cmd.Run()
	code := 0
	if ee, ok := err.(*exec.ExitError); ok {
		code = ee.ExitCode()
	} else if err != nil {
		f.t.Fatal(err)
	}
	f.t.Logf("bakery %s (exit %d)\n%s", strings.Join(args, " "), code, out.String())
	return result{out.String(), code}
}

// mavenRepo is a mock Maven repository serving files from a directory.
type mavenRepo struct {
	*httptest.Server
	dir      string
	user     string
	pass     string
	mu       sync.Mutex
	requests []string
}

func newMavenRepo(t *testing.T, user, pass string) *mavenRepo {
	r := &mavenRepo{dir: t.TempDir(), user: user, pass: pass}
	r.Server = httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
		r.mu.Lock()
		r.requests = append(r.requests, req.URL.Path+" auth="+req.Header.Get("Authorization"))
		r.mu.Unlock()
		if strings.Contains(req.URL.Path, "forbidden") {
			http.Error(w, "forbidden", http.StatusForbidden)
			return
		}
		if r.user != "" {
			u, p, ok := req.BasicAuth()
			if !ok || u != r.user || p != r.pass {
				http.Error(w, "unauthorized", http.StatusUnauthorized)
				return
			}
		}
		http.ServeFile(w, req, filepath.Join(r.dir, filepath.FromSlash(req.URL.Path)))
	}))
	t.Cleanup(r.Close)
	return r
}

// seed places an artifact at its Maven GAV path and returns its content.
func (r *mavenRepo) seed(t *testing.T, group, name, version, classifier, content string) string {
	t.Helper()
	if content == "" {
		content = fmt.Sprintf("artifact-bytes-%s-%s\n", name, version)
	}
	dir := filepath.Join(r.dir, strings.ReplaceAll(group, ".", "/"), name, version)
	must(t, os.MkdirAll(dir, 0o755))
	must(t, os.WriteFile(filepath.Join(dir, name+"-"+version+classifier), []byte(content), 0o644))
	return content
}

func (r *mavenRepo) log() string {
	r.mu.Lock()
	defer r.mu.Unlock()
	return strings.Join(r.requests, "\n")
}

func basicAuth(user, pass string) string {
	return "Basic " + base64.StdEncoding.EncodeToString([]byte(user+":"+pass))
}

func manifest(entries ...string) string {
	return "artifacts:\n" + strings.Join(entries, "")
}

// artifact renders one manifest entry; extra holds additional "key: value" lines.
func artifact(name, version, group, source, path string, extra ...string) string {
	s := fmt.Sprintf("  %s:\n    name: %s\n    version: %s\n    classifier: .jar\n    group: %s\n", name, name, version, group)
	if source != "" {
		s += "    source: " + source + "\n"
	}
	s += "    path: " + path + "\n"
	for _, e := range extra {
		s += "    " + e + "\n"
	}
	return s
}

func assertContains(t *testing.T, s, sub string) {
	t.Helper()
	if !strings.Contains(s, sub) {
		t.Errorf("expected output to contain %q", sub)
	}
}

func assertNotContains(t *testing.T, s, sub string) {
	t.Helper()
	if strings.Contains(s, sub) {
		t.Errorf("expected output not to contain %q", sub)
	}
}
