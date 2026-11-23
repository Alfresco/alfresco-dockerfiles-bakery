package artifacts

import (
	"io"
	"path/filepath"
	"strings"
	"testing"

	"github.com/Alfresco/alfresco-dockerfiles-bakery/internal/logx"
)

// The source model must build the same URLs as the legacy layout
// <nexus>/<repository>/<group path>/<name>/<version>/<file>, where the
// repository is now the source name, for every manifest in this checkout.
func TestURLParityWithLegacyNexusLayout(t *testing.T) {
	const legacyBase = "https://nexus.alfresco.com/nexus/repository"
	root, err := filepath.Abs("../..")
	if err != nil {
		t.Fatal(err)
	}
	log, _ := logx.New(io.Discard, logx.Error, "")
	f := &Fetcher{Root: root, NetrcPath: filepath.Join(t.TempDir(), "none"), Log: log}
	sources, err := f.loadSources()
	if err != nil {
		t.Fatal(err)
	}
	f.sources = sources

	manifests, err := walkManifests(root, root, func(rel string) bool {
		ok, _ := filepath.Match("artifacts-*.yaml", filepath.Base(rel))
		return ok
	})
	if err != nil {
		t.Fatal(err)
	}
	checked := 0
	for _, rel := range manifests {
		order, entries, err := readManifest(filepath.Join(root, rel))
		if err != nil {
			t.Fatal(err)
		}
		for _, key := range order {
			a, err := f.resolve(entries[key])
			if err != nil {
				t.Errorf("%s: %v", rel, err)
				continue
			}
			want := strings.Join([]string{legacyBase, str(entries[key], "source"), strings.ReplaceAll(a.group, ".", "/"), a.name, a.version, a.filename()}, "/")
			if got := a.url(); got != want {
				t.Errorf("%s: %s\n  got  %s\n  want %s", rel, key, got, want)
			}
			checked++
		}
	}
	if checked == 0 {
		t.Fatal("no artifacts checked")
	}
	t.Logf("%d artifacts match the legacy Nexus layout", checked)
}
