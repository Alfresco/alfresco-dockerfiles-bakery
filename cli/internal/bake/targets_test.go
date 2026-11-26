package bake

import (
	"cmp"
	"encoding/json"
	"io/fs"
	"os/exec"
	"path/filepath"
	"slices"
	"strings"
	"testing"
)

type bakeTarget struct {
	Context  string            `json:"context"`
	Contexts map[string]string `json:"contexts"`
	Output   []bakeOutput      `json:"output"`
}

type bakeOutput struct {
	Type string `json:"type"`
}

// bakeRoot skips the test without docker buildx and returns the repo root.
func bakeRoot(t *testing.T) string {
	t.Helper()
	if err := exec.Command("docker", "buildx", "version").Run(); err != nil {
		t.Skip("docker buildx is not available")
	}
	root, err := filepath.Abs("../../..")
	if err != nil {
		t.Fatal(err)
	}
	return root
}

func bakeJSON(t *testing.T, root string, v any, args ...string) {
	t.Helper()
	cmd := exec.Command("docker", append([]string{"buildx", "bake"}, args...)...)
	cmd.Dir = root
	out, err := cmd.Output()
	if err != nil {
		t.Fatalf("docker buildx bake %s: %v", strings.Join(args, " "), err)
	}
	if err := json.Unmarshal(out, v); err != nil {
		t.Fatal(err)
	}
}

func bakePrint(t *testing.T, root string, names ...string) map[string]bakeTarget {
	t.Helper()
	var printed struct {
		Target map[string]bakeTarget `json:"target"`
	}
	bakeJSON(t, root, &printed, append([]string{"--print"}, names...)...)
	return printed.Target
}

// TestTargetsMatchBakeFile catches the targets table drifting from
// docker-bake.hcl: every row must name a bake group or target, and fetch
// every build context of it that holds an artifacts manifest.
func TestTargetsMatchBakeFile(t *testing.T) {
	root := bakeRoot(t)
	for _, tg := range targets {
		if tg.fetch == nil {
			continue
		}
		t.Run(tg.Name, func(t *testing.T) {
			scope := tg.fetch(Options{ACSVersion: "26", APSVersion: "26"})
			for name, bt := range bakePrint(t, root, tg.bake) {
				dirs := []string{bt.Context}
				for _, c := range bt.Contexts {
					if !strings.HasPrefix(c, "target:") {
						dirs = append(dirs, c)
					}
				}
				for _, d := range dirs {
					d = filepath.ToSlash(filepath.Clean(d))
					if hasManifest(t, filepath.Join(root, d)) && !covered(d, scope) {
						t.Errorf("bake target %s builds from %s, which holds artifact manifests outside the fetch scope %v", name, d, scope)
					}
				}
			}
		})
	}
}

// TestEveryBakeImageHasTarget fails when docker-bake.hcl gains an image that
// no row of the targets table builds.
func TestEveryBakeImageHasTarget(t *testing.T) {
	root := bakeRoot(t)
	var listed []struct {
		Name  string `json:"name"`
		Group bool   `json:"group"`
	}
	bakeJSON(t, root, &listed, "--list", "type=targets,format=json")
	var images []string
	for _, l := range listed {
		if !l.Group {
			images = append(images, l.Name)
		}
	}

	built := map[string]bool{}
	for _, tg := range targets {
		for name := range bakePrint(t, root, cmp.Or(tg.bake, "default")) {
			built[name] = true
		}
	}
	for name, bt := range bakePrint(t, root, images...) {
		cacheOnly := slices.ContainsFunc(bt.Output, func(o bakeOutput) bool { return o.Type == "cacheonly" })
		if !cacheOnly && !built[name] {
			t.Errorf("bake target %s is not built by any bakery build target; add a row to the targets table in bake.go", name)
		}
	}
}

func hasManifest(t *testing.T, dir string) bool {
	t.Helper()
	found := false
	err := filepath.WalkDir(dir, func(p string, d fs.DirEntry, err error) error {
		if err != nil || found {
			return fs.SkipAll
		}
		if ok, _ := filepath.Match("artifacts-*.yaml", d.Name()); ok && !d.IsDir() {
			found = true
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	return found
}

// covered reports whether dir lies under a fetch scope entry; a glob counts
// from its leading literal directories.
func covered(dir string, scope []string) bool {
	for _, s := range scope {
		if i := strings.IndexAny(s, "*?"); i >= 0 {
			s = filepath.Dir(s[:i+1])
		}
		if dir == s || strings.HasPrefix(dir, s+"/") {
			return true
		}
	}
	return false
}
