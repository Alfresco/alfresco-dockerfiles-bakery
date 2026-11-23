package artifacts

import (
	"encoding/json"
	"path/filepath"
	"slices"
	"strings"

	"github.com/Alfresco/alfresco-dockerfiles-bakery/cli/internal/repo"
)

// VersionsJSON returns the {artifact name: version} map of every ACS manifest
// for acsVersion outside aps/ and every APS manifest for apsVersion, as JSON.
// APS manifests are applied last, so they win on a name clash.
func VersionsJSON(root, acsVersion, apsVersion string) (string, error) {
	acsName, apsName := manifestName(acsVersion), manifestName(apsVersion)
	inAPS := func(rel string) bool { return strings.HasPrefix(rel, "aps/") }
	all, err := repo.Walk(root, root, func(rel string) bool {
		if inAPS(rel) {
			return filepath.Base(rel) == apsName
		}
		return filepath.Base(rel) == acsName
	})
	if err != nil {
		return "", err
	}
	acs := slices.DeleteFunc(slices.Clone(all), inAPS)
	aps := slices.DeleteFunc(all, func(rel string) bool { return !inAPS(rel) })

	versions := map[string]any{}
	for _, rel := range append(acs, aps...) {
		_, entries, err := readManifest(filepath.Join(root, filepath.FromSlash(rel)))
		if err != nil {
			return "", err
		}
		for name, details := range entries {
			if v, ok := details["version"]; ok && v != nil {
				versions[name] = v
			}
		}
	}
	out, err := json.Marshal(versions)
	return string(out), err
}
