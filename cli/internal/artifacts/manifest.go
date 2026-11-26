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

type entry struct {
	key    string
	fields map[string]any
}

// readManifest returns the entries of a manifest's artifacts map in file order.
func readManifest(path string) ([]entry, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var doc yaml.Node
	if err := yaml.Unmarshal(data, &doc); err != nil {
		return nil, fmt.Errorf("parsing %s: %w", path, err)
	}
	if len(doc.Content) == 0 {
		return nil, nil
	}
	var parsed struct {
		Artifacts yaml.Node `yaml:"artifacts"`
	}
	if err := doc.Content[0].Decode(&parsed); err != nil {
		return nil, fmt.Errorf("parsing %s: %w", path, err)
	}
	n := parsed.Artifacts
	if n.Kind != yaml.MappingNode {
		// Missing or null artifacts mean an empty manifest; anything else is malformed.
		var m map[string]any
		if err := n.Decode(&m); err != nil && n.Kind != 0 {
			return nil, fmt.Errorf("parsing %s: %w", path, err)
		}
		return nil, nil
	}
	entries := make([]entry, 0, len(n.Content)/2)
	for i := 0; i < len(n.Content); i += 2 {
		e := entry{key: n.Content[i].Value}
		if err := n.Content[i+1].Decode(&e.fields); err != nil {
			return nil, fmt.Errorf("parsing %s: %w", path, err)
		}
		entries = append(entries, e)
	}
	return entries, nil
}
