package artifacts

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/bmatcuk/doublestar/v4"
	"gopkg.in/yaml.v3"

	"github.com/Alfresco/alfresco-dockerfiles-bakery/cli/internal/repo"
)

func manifestName(version string) string { return "artifacts-" + version + ".yaml" }

func isGlob(s string) bool { return strings.ContainsAny(s, "*?") }

// findManifests resolves one fetch target: an existing directory (searched for
// artifacts-<acsVersion>.yaml), an existing file, or a glob pattern relative
// to root.
func (f *Fetcher) findManifests(target string) ([]string, error) {
	path := target
	if !filepath.IsAbs(path) {
		path = filepath.Join(f.Root, target)
	}
	if info, err := os.Stat(path); err == nil {
		f.Log.Debugf("Argument '%s' is a valid path.", target)
		if !info.IsDir() {
			rel, err := filepath.Rel(f.Root, path)
			if err != nil {
				return nil, err
			}
			return []string{filepath.ToSlash(rel)}, nil
		}
		want := manifestName(f.ACSVersion)
		return repo.Walk(f.Root, path, func(rel string) bool { return filepath.Base(rel) == want })
	}
	if isGlob(target) {
		f.Log.Debugf("Argument '%s' is a glob pattern.", target)
		pattern := filepath.ToSlash(target)
		if !doublestar.ValidatePattern(pattern) {
			return nil, fmt.Errorf("invalid glob pattern %q", target)
		}
		return repo.Walk(f.Root, f.Root, func(rel string) bool {
			ok, _ := doublestar.Match(pattern, rel)
			return ok
		})
	}
	return nil, fmt.Errorf("fetch target %q is neither an existing path nor a glob pattern", target)
}

// readManifest returns the artifacts map of a manifest, keyed by entry name,
// in file order.
func readManifest(path string) ([]string, map[string]map[string]any, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, nil, err
	}
	var doc yaml.Node
	if err := yaml.Unmarshal(data, &doc); err != nil {
		return nil, nil, fmt.Errorf("parsing %s: %w", path, err)
	}
	var parsed struct {
		Artifacts yaml.Node `yaml:"artifacts"`
	}
	if len(doc.Content) == 0 {
		return nil, nil, nil
	}
	if err := doc.Content[0].Decode(&parsed); err != nil {
		return nil, nil, fmt.Errorf("parsing %s: %w", path, err)
	}
	var entries map[string]map[string]any
	if err := parsed.Artifacts.Decode(&entries); err != nil && parsed.Artifacts.Kind != 0 {
		return nil, nil, fmt.Errorf("parsing %s: %w", path, err)
	}
	var order []string
	if parsed.Artifacts.Kind == yaml.MappingNode {
		for i := 0; i < len(parsed.Artifacts.Content); i += 2 {
			order = append(order, parsed.Artifacts.Content[i].Value)
		}
	}
	return order, entries, nil
}
