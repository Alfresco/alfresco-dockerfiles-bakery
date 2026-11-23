package main

import (
	"encoding/json"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
)

// bakeFixture is a checkout with one empty manifest per fetch scope, so a
// build's fetch step logs which manifests it processed.
func bakeFixture(t *testing.T) *fixture {
	f := newFixture(t)
	for _, dir := range []string{"repository", "share", "tengine/tika", "ats/sfs", "search/community", "adf-apps/acc"} {
		f.write(dir+"/artifacts-26.yaml", "artifacts: {}\n")
	}
	f.write("aps/app/artifacts-26.yaml", "artifacts: {}\n")
	f.write("aps/app/artifacts-24.yaml", "artifacts: {}\n")
	// Already present and without checksum, so fetching it needs no download.
	f.write("repository/artifacts-23.yaml", manifest(artifact("alfresco-content-repository", "23.4.0", "org.alfresco", "public", "repository/libs")))
	f.write("repository/libs/alfresco-content-repository-23.4.0.jar", "")
	return f
}

// bakeCalls returns the logged "docker buildx bake" command lines, excluding --print.
func bakeCalls(log string) []string {
	var out []string
	for _, l := range strings.Split(log, "\n") {
		if strings.HasPrefix(l, "docker buildx bake") && !strings.Contains(l, "--print") {
			out = append(out, l)
		}
	}
	return out
}

func TestVersionsMap(t *testing.T) {
	f := newFixture(t)
	f.write("top/artifacts-999.yaml", "artifacts:\n  top-artifact:\n    version: \"1.2.3\"\n  no-version:\n    name: x\n")
	f.write("aps/x/artifacts-998.yaml", "artifacts:\n  aps-artifact:\n    version: \"4.5.6\"\n")
	f.write("aps/x/artifacts-999.yaml", "artifacts:\n  aps-as-acs:\n    version: \"0.0.1\"\n")

	res := f.run("", "versions", "--acs-version", "999", "--aps-version", "998")
	if res.code != 0 {
		t.Fatal("versions failed")
	}
	var got map[string]any
	must(t, json.Unmarshal([]byte(strings.TrimSpace(res.out)), &got))
	if len(got) != 2 || got["top-artifact"] != "1.2.3" || got["aps-artifact"] != "4.5.6" {
		t.Errorf("got %v, want top-artifact 1.2.3 and aps-artifact 4.5.6 only", got)
	}

	f.env = []string{"ACS_VERSION=999", "APS_VERSION=998"}
	if res2 := f.run("", "versions"); res2.out != res.out {
		t.Error("ACS_VERSION/APS_VERSION env vars not honoured")
	}
}

func TestBuildLocal(t *testing.T) {
	f := bakeFixture(t)
	res := f.run("", "build", "repository", "--acs-version", "23", "--log-level", "DEBUG")
	if res.code != 0 {
		t.Fatal("build failed")
	}
	assertContains(t, res.out, "Images will be build & loaded locally")
	assertContains(t, res.out, "TAG=<none, tags come from artifact versions>")
	assertContains(t, res.out, "Processing target: repository")

	calls := bakeCalls(f.calls())
	if len(calls) != 1 || calls[0] != "docker buildx bake --progress=plain repository" {
		t.Fatalf("unexpected bake calls %q", calls)
	}
	log := f.calls()
	assertContains(t, log, "ACS_VERSION=23")
	assertContains(t, log, "APS_VERSION=26")
	assertContains(t, log, `ARTIFACT_VERSIONS={"alfresco-content-repository":"23.4.0"}`)
	assertNotContains(t, log, "REGISTRY=")
	assertNotContains(t, log, "docker login")
}

func TestBuildFetchScopes(t *testing.T) {
	cases := []struct {
		target   string
		fetched  []string
		bakeArgs []string
	}{
		{"share", []string{"share/artifacts-26.yaml"}, []string{"share"}},
		{"aps", []string{"aps/app/artifacts-26.yaml"}, []string{"aps"}},
		{"search_batch_indexing", []string{"search/community/artifacts-26.yaml"}, []string{"search_batch_indexing"}},
		{"ats", []string{"tengine/tika/artifacts-26.yaml", "ats/sfs/artifacts-26.yaml"}, []string{"tengines", "ats"}},
		{"all", []string{"repository/artifacts-26.yaml", "aps/app/artifacts-26.yaml", "adf-apps/acc/artifacts-26.yaml"}, []string{""}},
		{"enterprise", []string{"repository/artifacts-26.yaml", "share/artifacts-26.yaml"}, []string{"enterprise"}},
	}
	for _, c := range cases {
		t.Run(c.target, func(t *testing.T) {
			f := bakeFixture(t)
			res := f.run("", "build", c.target, "--log-level", "DEBUG")
			if res.code != 0 {
				t.Fatal("build failed")
			}
			for _, m := range c.fetched {
				assertContains(t, res.out, "Processing manifest "+m)
			}
			if c.target == "aps" {
				assertNotContains(t, res.out, "aps/app/artifacts-24.yaml")
				assertNotContains(t, res.out, "share/artifacts-26.yaml")
			}
			calls := bakeCalls(f.calls())
			if len(calls) != len(c.bakeArgs) {
				t.Fatalf("unexpected bake calls %q", calls)
			}
			for i, a := range c.bakeArgs {
				want := strings.TrimSpace("docker buildx bake --progress=plain " + a)
				if calls[i] != want {
					t.Errorf("bake call %d = %q, want %q", i, calls[i], want)
				}
			}
		})
	}
}

func TestBuildUnknownTarget(t *testing.T) {
	f := bakeFixture(t)
	res := f.run("", "build", "nope")
	if res.code == 0 {
		t.Fatal("expected failure")
	}
	assertContains(t, res.out, `unknown target "nope"`)
	assertContains(t, res.out, "repository")
	if len(bakeCalls(f.calls())) != 0 {
		t.Error("bake must not run")
	}
}

func TestBuildHelpListsTargets(t *testing.T) {
	f := newFixture(t)
	res := f.run("", "build", "--help")
	for _, name := range []string{"all", "enterprise", "community", "adf_apps", "aps", "ats", "audit_storage", "connectors",
		"cic_connector", "repository", "search_batch_indexing", "search_enterprise", "search_service", "share", "sync", "tengines"} {
		if !regexp.MustCompile(`(?m)^\s+` + name + `\s`).MatchString(res.out) {
			t.Errorf("help does not list target %s", name)
		}
	}
}

func TestBuildPushConfirmed(t *testing.T) {
	f := bakeFixture(t)
	f.env = []string{"REGISTRY=quay.io", "REGISTRY_NAMESPACE=myorg", "TAG=custom"}
	res := f.run("y\n", "build", "share")
	if res.code != 0 {
		t.Fatal("build failed")
	}
	assertContains(t, res.out, "Images will be pushed to quay.io/myorg")
	assertContains(t, res.out, "Do you want to continue? [y/N]")
	log := f.calls()
	assertContains(t, log, "docker login quay.io")
	calls := bakeCalls(log)
	want := "docker buildx bake --progress=plain --set *.output=type=registry,push=true --sbom=true --provenance=false share"
	if len(calls) != 1 || calls[0] != want {
		t.Fatalf("bake calls %q, want %q", calls, want)
	}
	assertContains(t, log, "REGISTRY=quay.io")
	assertContains(t, log, "REGISTRY_NAMESPACE=myorg")
	assertContains(t, log, "TAG=custom")
}

func TestBuildPushFlags(t *testing.T) {
	f := bakeFixture(t)
	res := f.run("", "build", "share", "--registry", "quay.io", "--yes", "--no-sbom", "--provenance", "mode=max", "--no-cache")
	if res.code != 0 {
		t.Fatal("build failed")
	}
	assertNotContains(t, res.out, "Do you want to continue?")
	calls := bakeCalls(f.calls())
	want := "docker buildx bake --progress=plain --no-cache --set *.output=type=registry,push=true --provenance=mode=max share"
	if len(calls) != 1 || calls[0] != want {
		t.Fatalf("bake calls %q, want %q", calls, want)
	}
}

func TestBuildFlagsFromEnv(t *testing.T) {
	f := bakeFixture(t)
	f.env = []string{"REGISTRY=quay.io", "BAKE_NO_CACHE=1", "BAKE_NO_SBOM=1", "BAKE_PROVENANCE=mode=max"}
	if res := f.run("", "build", "share", "--yes"); res.code != 0 {
		t.Fatal("build failed")
	}
	calls := bakeCalls(f.calls())
	want := "docker buildx bake --progress=plain --no-cache --set *.output=type=registry,push=true --provenance=mode=max share"
	if len(calls) != 1 || calls[0] != want {
		t.Fatalf("bake calls %q, want %q", calls, want)
	}
}

func TestBuildPushDeclined(t *testing.T) {
	for _, stdin := range []string{"n\n", ""} {
		f := bakeFixture(t)
		res := f.run(stdin, "build", "share", "--registry", "quay.io")
		if res.code == 0 {
			t.Fatalf("stdin %q: expected the build to stop", stdin)
		}
		assertContains(t, res.out, "Stopping build")
		if len(bakeCalls(f.calls())) != 0 {
			t.Errorf("stdin %q: bake must not run", stdin)
		}
	}
}

func TestBuildPushLoginFails(t *testing.T) {
	f := bakeFixture(t)
	f.env = []string{"FAKE_LOGIN_EXIT=1"}
	res := f.run("y\n", "build", "share", "--registry", "quay.io")
	if res.code == 0 {
		t.Fatal("expected failure")
	}
	assertContains(t, res.out, "Failed to login to quay.io. Stopping build.")
	if len(bakeCalls(f.calls())) != 0 {
		t.Error("bake must not run")
	}
}

func TestBuildLocalhostRegistryLoadsLocally(t *testing.T) {
	f := bakeFixture(t)
	res := f.run("", "build", "share", "--registry", "localhost")
	if res.code != 0 {
		t.Fatal("build failed")
	}
	assertContains(t, res.out, "REGISTRY environment variable is set to localhost")
	calls := bakeCalls(f.calls())
	if len(calls) != 1 || calls[0] != "docker buildx bake --progress=plain share" {
		t.Fatalf("unexpected bake calls %q", calls)
	}
	assertContains(t, f.calls(), "REGISTRY=localhost")
}

const printJSON = `{"target":{
  "java_base":{"tags":["localhost/alfresco/alfresco-base-java:jre21"],"output":[{"type":"cacheonly"}]},
  "share_enterprise":{"tags":["localhost/alfresco/alfresco-share:26.1.0","localhost/alfresco/alfresco-share:latest"],"output":[{"type":"docker"}]},
  "pushed":{"tags":["quay.io/x/y:1"],"output":[{"type":"registry"}]}
}}`

func TestGrype(t *testing.T) {
	f := bakeFixture(t)
	must(t, os.WriteFile(f.print, []byte(printJSON), 0o644))
	out := filepath.Join(f.root, "sarif")
	res := f.run("", "grype", "share", "--grype-output-dir", out, "--grype-output-format", "sarif", "--grype-opts", "--only-fixed --ignore-states wont-fix")
	if res.code != 0 {
		t.Fatal("grype failed")
	}
	log := f.calls()
	assertContains(t, log, "docker buildx bake share --print")
	assertContains(t, log, "grype --only-fixed --ignore-states wont-fix -o sarif localhost/alfresco/alfresco-share:26.1.0")
	assertContains(t, log, "grype --only-fixed --ignore-states wont-fix -o sarif localhost/alfresco/alfresco-share:latest")
	assertNotContains(t, log, "alfresco-base-java")
	assertNotContains(t, log, "quay.io/x/y")
	report, err := os.ReadFile(filepath.Join(out, "localhost_alfresco_alfresco-share_26.1.0.out"))
	must(t, err)
	assertContains(t, string(report), "report for")
}

func TestGrypeDefaultOptsToStdout(t *testing.T) {
	f := bakeFixture(t)
	must(t, os.WriteFile(f.print, []byte(printJSON), 0o644))
	res := f.run("", "grype")
	if res.code != 0 {
		t.Fatal("grype failed")
	}
	assertContains(t, f.calls(), "docker buildx bake --print\n")
	assertContains(t, f.calls(), "grype -f high --only-fixed --ignore-states wont-fix localhost/alfresco/alfresco-share:latest")
	assertContains(t, res.out, "Scanning image localhost/alfresco/alfresco-share:latest")
	assertContains(t, res.out, "report for")
}

func TestGrypeOptsKeepQuotedValues(t *testing.T) {
	f := bakeFixture(t)
	must(t, os.WriteFile(f.print, []byte(printJSON), 0o644))
	res := f.run("", "grype", "share", "--grype-opts", `--config "my configs/grype.yaml" --only-fixed`)
	if res.code != 0 {
		t.Fatal("grype failed")
	}
	assertContains(t, f.calls(), "argv: [--config] [my configs/grype.yaml] [--only-fixed] [localhost/alfresco/alfresco-share:26.1.0]")
}

func TestGrypeTargetFromEnv(t *testing.T) {
	f := bakeFixture(t)
	must(t, os.WriteFile(f.print, []byte(printJSON), 0o644))
	f.env = []string{"GRYPE_TARGET=aps"}
	if res := f.run("", "grype"); res.code != 0 {
		t.Fatal("grype failed")
	}
	assertContains(t, f.calls(), "docker buildx bake aps --print")

	f.run("", "grype", "share")
	assertContains(t, f.calls(), "docker buildx bake share --print")
}

func TestEmptyFlagsOverrideInheritedEnv(t *testing.T) {
	f := bakeFixture(t)
	f.env = []string{"REGISTRY=quay.io", "REGISTRY_NAMESPACE=myorg", "TAG=custom"}
	res := f.run("", "build", "share", "--registry", "", "--namespace", "", "--tag", "")
	if res.code != 0 {
		t.Fatal("build failed")
	}
	log := f.calls()
	assertNotContains(t, log, "docker login")
	bakeAt := strings.Index(log, "docker buildx bake --progress=plain share")
	if bakeAt < 0 {
		t.Fatal("bake did not run")
	}
	for _, v := range []string{"REGISTRY=quay.io", "REGISTRY_NAMESPACE=myorg", "TAG=custom"} {
		assertNotContains(t, log[bakeAt:], v)
	}
}

func TestGrypeMissing(t *testing.T) {
	f := bakeFixture(t)
	must(t, os.Remove(filepath.Join(f.bin, "grype")))
	res := f.run("", "grype", "share")
	if res.code == 0 {
		t.Fatal("expected failure")
	}
	assertContains(t, res.out, "grype is required")
}

func TestBuildWithGrype(t *testing.T) {
	f := bakeFixture(t)
	must(t, os.WriteFile(f.print, []byte(printJSON), 0o644))
	res := f.run("", "build", "share", "--grype")
	if res.code != 0 {
		t.Fatal("build failed")
	}
	log := f.calls()
	bakeAt := strings.Index(log, "docker buildx bake --progress=plain share")
	scanAt := strings.Index(log, "grype ")
	if bakeAt < 0 || scanAt < bakeAt {
		t.Error("grype must run after the build")
	}
}

func TestBuildRequiresBuildx(t *testing.T) {
	f := bakeFixture(t)
	must(t, os.Remove(filepath.Join(f.bin, "docker")))
	res := f.run("", "build", "share")
	if res.code == 0 {
		t.Fatal("expected failure")
	}
	assertContains(t, res.out, "docker buildx")
}

func TestCleanArtifacts(t *testing.T) {
	f := newFixture(t)
	f.write("repository/libs/postgresql-42.7.10.jar", "")
	f.write("tengine/aio/alfresco-transform-core-aio-5.1.jar", "")
	f.write("repository/libs/README.md", "")
	f.write("artifacts_cache/public/abc/postgresql-42.7.10.jar", "")
	f.write(".claude/worktrees/x/repository/libs/postgresql-42.7.10.jar", "")

	res := f.run("n\n", "clean")
	assertContains(t, res.out, "repository/libs/postgresql-42.7.10.jar")
	assertContains(t, res.out, "Operation cancelled.")
	if !f.exists("repository/libs/postgresql-42.7.10.jar") {
		t.Fatal("deleted without confirmation")
	}

	res = f.run("", "clean", "-f")
	if res.code != 0 {
		t.Fatal("clean failed")
	}
	if f.exists("repository/libs/postgresql-42.7.10.jar") || f.exists("tengine/aio/alfresco-transform-core-aio-5.1.jar") {
		t.Error("artifacts not deleted")
	}
	for _, keep := range []string{"repository/libs/README.md", "artifacts_cache/public/abc/postgresql-42.7.10.jar", ".claude/worktrees/x/repository/libs/postgresql-42.7.10.jar"} {
		if !f.exists(keep) {
			t.Errorf("%s must be kept", keep)
		}
	}

	res = f.run("", "clean", "-f")
	assertContains(t, res.out, "No artifacts found to clean.")
}

func TestCleanCaches(t *testing.T) {
	f := newFixture(t)
	f.write("artifacts_cache/.gitkeep", "")
	f.write("artifacts_cache/public/abc/postgresql-42.7.10.jar", "")
	res := f.run("", "clean", "--caches")
	if res.code != 0 {
		t.Fatal("clean --caches failed")
	}
	assertContains(t, f.calls(), "docker builder prune -f")
	if f.exists("artifacts_cache/public") || !f.exists("artifacts_cache/.gitkeep") {
		t.Error("artifacts_cache not emptied correctly")
	}
}

func TestRunsFromSubdirectory(t *testing.T) {
	f := newFixture(t)
	f.write("top/artifacts-26.yaml", "artifacts:\n  a:\n    version: \"1\"\n")
	sub := filepath.Join(f.root, "top")
	f.root = sub
	res := f.run("", "versions")
	if res.code != 0 || !strings.Contains(res.out, `"a":"1"`) {
		t.Fatal("repository root not found from a subdirectory")
	}

	f.root = t.TempDir()
	res = f.run("", "versions")
	if res.code == 0 {
		t.Fatal("expected failure outside a checkout")
	}
	assertContains(t, res.out, "docker-bake.hcl")
}
