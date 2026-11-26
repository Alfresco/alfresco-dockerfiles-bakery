// Package repo locates the Bakery checkout the CLI operates on and walks it.
package repo

import (
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"slices"
	"strings"
)

const markerFile = "docker-bake.hcl"

// CacheDir is the artifact download cache, relative to the root.
const CacheDir = "artifacts_cache"

// FindRoot walks up from start to the first directory holding docker-bake.hcl.
func FindRoot(start string) (string, error) {
	dir, err := filepath.Abs(start)
	if err != nil {
		return "", err
	}
	for {
		if _, err := os.Stat(filepath.Join(dir, markerFile)); err == nil {
			return dir, nil
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			return "", fmt.Errorf("no %s found in %s or its parents: run bakery inside a Bakery checkout or pass --dir", markerFile, start)
		}
		dir = parent
	}
}

// Walk returns the sorted, slash-separated paths relative to root of the
// regular files under dir accepted by match. It skips hidden directories, so
// git worktrees under .claude/ are never picked up, and the download cache.
func Walk(root, dir string, match func(rel string) bool) ([]string, error) {
	var out []string
	err := filepath.WalkDir(dir, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		rel, err := filepath.Rel(root, path)
		if err != nil {
			return err
		}
		rel = filepath.ToSlash(rel)
		if d.IsDir() {
			if path != dir && (strings.HasPrefix(d.Name(), ".") || rel == CacheDir) {
				return filepath.SkipDir
			}
			return nil
		}
		if d.Type().IsRegular() && match(rel) {
			out = append(out, rel)
		}
		return nil
	})
	slices.Sort(out)
	return out, err
}
