// Package clean removes fetched artifacts and build caches.
package clean

import (
	"context"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"

	"github.com/Alfresco/alfresco-dockerfiles-bakery/cli/internal/prompt"
	"github.com/Alfresco/alfresco-dockerfiles-bakery/cli/internal/repo"
)

var artifactFile = regexp.MustCompile(`^.*-.*\.(jar|zip|amp|tgz|gz|rpm|deb|war)$`)

// Artifacts deletes fetched artifacts from the image build contexts, asking
// for confirmation on in unless force is set.
func Artifacts(root string, force bool, in io.Reader, out io.Writer) error {
	files, err := repo.Walk(root, root, artifactFile.MatchString)
	if err != nil {
		return err
	}
	if len(files) == 0 {
		fmt.Fprintln(out, "No artifacts found to clean.")
		return nil
	}
	fmt.Fprintln(out, "The following files will be deleted:")
	for _, f := range files {
		fmt.Fprintln(out, f)
	}
	if !force {
		fmt.Fprint(out, "Do you want to delete these files? (y/n) ")
		if !prompt.Confirm(in) {
			fmt.Fprintln(out, "\nOperation cancelled.")
			return nil
		}
	}
	for _, f := range files {
		if err := os.Remove(filepath.Join(root, filepath.FromSlash(f))); err != nil {
			return err
		}
	}
	fmt.Fprintln(out, "All artifacts deleted.")
	return nil
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
	dir := filepath.Join(root, repo.CacheDir)
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
