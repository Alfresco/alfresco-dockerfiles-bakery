package bake

import (
	"encoding/json"
	"io/fs"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

// TestTargetsMatchBakeFile catches the targets table drifting from
// docker-bake.hcl: every row must name a bake group or target, and fetch
// every build context of it that holds an artifacts manifest.
func TestTargetsMatchBakeFile(t *testing.T) {
	if err := exec.Command("docker", "buildx", "version").Run(); err != nil {
		t.Skip("docker buildx is not available")
	}
	root, err := filepath.Abs("../../..")
	if err != nil {
		t.Fatal(err)
	}
	for _, tg := range targets {
		if tg.fetch == nil {
			continue
		}
		t.Run(tg.Name, func(t *testing.T) {
			cmd := exec.Command("docker", "buildx", "bake", "--print", tg.bake)
			cmd.Dir = root
			out, err := cmd.Output()
			if err != nil {
				t.Fatalf("docker buildx bake --print %s: %v", tg.bake, err)
			}
			var printed struct {
				Target map[string]struct {
					Context  string            `json:"context"`
					Contexts map[string]string `json:"contexts"`
				} `json:"target"`
			}
			if err := json.Unmarshal(out, &printed); err != nil {
				t.Fatal(err)
			}
			scope := tg.fetch(Options{ACSVersion: "26", APSVersion: "26"})
			for name, bt := range printed.Target {
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
