// Package repo locates the Bakery checkout the CLI operates on.
package repo

import (
	"fmt"
	"os"
	"path/filepath"
)

// MarkerFile identifies the root of a Bakery checkout.
const MarkerFile = "docker-bake.hcl"

// FindRoot walks up from start to the first directory holding MarkerFile.
func FindRoot(start string) (string, error) {
	dir, err := filepath.Abs(start)
	if err != nil {
		return "", err
	}
	for {
		if _, err := os.Stat(filepath.Join(dir, MarkerFile)); err == nil {
			return dir, nil
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			return "", fmt.Errorf("no %s found in %s or its parents: run bakery inside a Bakery checkout or pass --dir", MarkerFile, start)
		}
		dir = parent
	}
}
