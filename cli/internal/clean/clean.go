// Package clean removes fetched artifacts and build caches.
package clean

import (
	"bufio"
	"context"
	"fmt"
	"io"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
)

var artifactFile = regexp.MustCompile(`^.*-.*\.(jar|zip|amp|tgz|gz|rpm|deb|war)$`)

// Artifacts deletes fetched artifacts from the image build contexts, asking
// for confirmation on in unless force is set.
func Artifacts(root string, force bool, in io.Reader, out io.Writer) error {
	var files []string
	err := filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		rel, _ := filepath.Rel(root, path)
		if d.IsDir() {
			if path != root && (strings.HasPrefix(d.Name(), ".") || rel == "artifacts_cache") {
				return filepath.SkipDir
			}
			return nil
		}
		if d.Type().IsRegular() && artifactFile.MatchString(filepath.ToSlash(rel)) {
			files = append(files, path)
		}
		return nil
	})
	if err != nil {
		return err
	}
	if len(files) == 0 {
		fmt.Fprintln(out, "No artifacts found to clean.")
		return nil
	}
	fmt.Fprintln(out, "The following files will be deleted:")
	for _, f := range files {
		rel, _ := filepath.Rel(root, f)
		fmt.Fprintln(out, filepath.ToSlash(rel))
	}
	if !force {
		fmt.Fprint(out, "Do you want to delete these files? (y/n) ")
		if !Confirm(in) {
			fmt.Fprintln(out, "\nOperation cancelled.")
			return nil
		}
	}
	for _, f := range files {
		if err := os.Remove(f); err != nil {
			return err
		}
	}
	fmt.Fprintln(out, "All artifacts deleted.")
	return nil
}

// Confirm reads one answer line and reports whether it starts with y or Y.
// End of input counts as no.
func Confirm(in io.Reader) bool {
	line, _ := bufio.NewReader(in).ReadString('\n')
	line = strings.TrimSpace(line)
	return line != "" && (line[0] == 'y' || line[0] == 'Y')
}

// Caches prunes the Docker build cache and empties artifacts_cache/.
func Caches(ctx context.Context, root string, out, errOut io.Writer) error {
	fmt.Fprintln(out, "Cleaning up Docker cache")
	cmd := exec.CommandContext(ctx, "docker", "builder", "prune", "-f")
	cmd.Stdout, cmd.Stderr = out, errOut
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("docker builder prune: %w", err)
	}
	fmt.Fprintln(out, "Cleaning up Artifacts cache")
	dir := filepath.Join(root, "artifacts_cache")
	entries, err := os.ReadDir(dir)
	if os.IsNotExist(err) {
		return nil
	} else if err != nil {
		return err
	}
	for _, e := range entries {
		if e.Name() == ".gitkeep" {
			continue
		}
		if err := os.RemoveAll(filepath.Join(dir, e.Name())); err != nil {
			return err
		}
	}
	return nil
}
