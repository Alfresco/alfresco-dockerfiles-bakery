// Package artifacts downloads the Maven artifacts declared in artifacts-*.yaml
// manifests and computes the version map used to tag images.
package artifacts

import (
	"crypto/md5"
	"crypto/sha1"
	"crypto/sha256"
	"crypto/sha512"
	"encoding/hex"
	"errors"
	"fmt"
	"hash"
	"io"
	"maps"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"slices"
	"strings"
	"time"

	"github.com/Alfresco/alfresco-dockerfiles-bakery/cli/internal/logx"
)

type Fetcher struct {
	Root        string
	SourcesFile string
	ACSVersion  string
	NetrcPath   string
	Log         *logx.Logger
	Client      *http.Client

	sourcesPath string
	sources     map[string]*source
	fetched     map[string]bool
	skipped     []skipped
}

type skipped struct {
	name, version, source, url string
	code                       int
}

type artifact struct {
	name, version, classifier, group, path, checksum string
	source                                           *source
}

func (a artifact) filename() string { return a.name + "-" + a.version + a.classifier }

func (a artifact) url() string {
	return fmt.Sprintf("%s/%s/%s/%s/%s", a.source.url, strings.ReplaceAll(a.group, ".", "/"), a.name, a.version, a.filename())
}

// Run fetches the artifacts of every manifest matched by targets: directories
// (searched for artifacts-<ACSVersion>.yaml), files or glob patterns, relative
// to Root. No targets means the whole repository.
func (f *Fetcher) Run(targets []string) error {
	if f.Client == nil {
		f.Client = &http.Client{Timeout: 30 * time.Minute}
	}
	if f.sources == nil {
		sources, err := f.loadSources()
		if err != nil {
			return err
		}
		f.sources = sources
	}
	f.fetched, f.skipped = map[string]bool{}, nil

	if len(targets) == 0 {
		targets = []string{"."}
	}
	for _, target := range targets {
		f.Log.Debugf("--- Processing target: %s ---", target)
		manifests, err := f.findManifests(target)
		if err != nil {
			return err
		}
		for _, rel := range manifests {
			if err := f.fetchManifest(rel); err != nil {
				return err
			}
		}
	}
	f.printSkipped()
	return nil
}

func (f *Fetcher) fetchManifest(rel string) error {
	f.Log.Debugf("Processing manifest %s", rel)
	order, entries, err := readManifest(filepath.Join(f.Root, filepath.FromSlash(rel)))
	if err != nil {
		return err
	}
	for _, key := range order {
		a, err := f.resolve(entries[key])
		if err != nil {
			return err
		}
		f.Log.Infof("")
		ok, err := f.fetch(a)
		if err != nil {
			return err
		}
		if ok {
			final := filepath.Join(a.path, a.filename())
			f.pruneStale(a, final)
			f.fetched[final] = true
		}
	}
	return nil
}

func str(m map[string]any, key string) string {
	if v, ok := m[key]; ok && v != nil {
		return fmt.Sprint(v)
	}
	return ""
}

// resolve validates a manifest entry and binds it to its source.
func (f *Fetcher) resolve(m map[string]any) (artifact, error) {
	a := artifact{
		name:       str(m, "name"),
		version:    str(m, "version"),
		classifier: str(m, "classifier"),
		group:      str(m, "group"),
		path:       str(m, "path"),
		checksum:   str(m, "checksum"),
	}
	if _, ok := m["repository"]; ok {
		return a, fmt.Errorf("artifact '%s' uses the removed 'repository' field; replace it with a 'source' defined in %s", a.name, f.sourcesPath)
	}
	name := str(m, "source")
	if name == "" {
		return a, fmt.Errorf("artifact '%s' has no 'source'; declare one defined in %s", a.name, f.sourcesPath)
	}
	s, ok := f.sources[name]
	if !ok {
		known := slices.Sorted(maps.Keys(f.sources))
		return a, fmt.Errorf("artifact '%s' references unknown source '%s'; define it in %s (known sources: %s)", a.name, name, f.sourcesPath, strings.Join(known, ", "))
	}
	a.source = s
	if !filepath.IsAbs(a.path) {
		a.path = filepath.Join(f.Root, filepath.FromSlash(a.path))
	}
	return a, nil
}

type httpError struct {
	url  string
	code int
}

func (e *httpError) Error() string { return fmt.Sprintf("HTTP %d fetching %s", e.code, e.url) }

func (f *Fetcher) get(url string, s *source) (io.ReadCloser, error) {
	req, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		return nil, err
	}
	if s.username != "" && s.password != "" {
		req.SetBasicAuth(s.username, s.password)
	}
	resp, err := f.Client.Do(req)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		resp.Body.Close()
		return nil, &httpError{url: url, code: resp.StatusCode}
	}
	return resp.Body, nil
}

var hashes = map[string]func() hash.Hash{"md5": md5.New, "sha1": sha1.New, "sha256": sha256.New, "sha512": sha512.New}

// checksum is the expected digest of an artifact; value is empty when there
// is nothing to verify against.
type checksum struct {
	algo, value string
}

// expectedChecksum resolves the manifest checksum, fetching the remote
// <artifact>.<algo> file when the manifest only names the algorithm.
func (f *Fetcher) expectedChecksum(a artifact) (checksum, error) {
	algo, value, _ := strings.Cut(a.checksum, ":")
	if _, ok := hashes[algo]; !ok {
		return checksum{}, nil
	}
	if value == "" {
		remote := a.url() + "." + algo
		body, err := f.get(remote, a.source)
		var httpErr *httpError
		if errors.As(err, &httpErr) {
			f.Log.Warnf("Failed to fetch checksum from %s: %v", remote, err)
			return checksum{}, nil
		} else if err != nil {
			return checksum{}, fmt.Errorf("fetching checksum from %s: %w", remote, err)
		}
		data, err := io.ReadAll(body)
		body.Close()
		if err != nil {
			return checksum{}, err
		}
		// Some repositories append the file name after the hash.
		if fields := strings.Fields(string(data)); len(fields) > 0 {
			value = fields[0]
		}
	}
	return checksum{algo, strings.ToLower(value)}, nil
}

// verify reports whether file matches c, and an error describing a mismatch.
func (c checksum) verify(file string) (bool, string, error) {
	if c.value == "" {
		return true, "", nil
	}
	in, err := os.Open(file)
	if err != nil {
		return false, "", err
	}
	defer in.Close()
	h := hashes[c.algo]()
	if _, err := io.Copy(h, in); err != nil {
		return false, "", err
	}
	actual := hex.EncodeToString(h.Sum(nil))
	return actual == c.value, actual, nil
}

// fetch puts the wanted version of a at its final path. It returns false when
// the download was skipped because of an authentication failure.
func (f *Fetcher) fetch(a artifact) (bool, error) {
	base := a.filename()
	final := filepath.Join(a.path, base)
	cacheDir := f.cacheDir(a.source)
	cached := filepath.Join(cacheDir, base)
	if err := os.MkdirAll(cacheDir, 0o755); err != nil {
		return false, err
	}

	// Resolved on first use, so a fetch needs the remote checksum at most once.
	var sum *checksum
	expected := func() (checksum, error) {
		if sum == nil {
			c, err := f.expectedChecksum(a)
			if err != nil {
				return c, err
			}
			sum = &c
		}
		return *sum, nil
	}

	if fileExists(final) {
		f.Log.Infof("Artifact %s-%s already present.", a.name, a.version)
		c, err := expected()
		if err != nil {
			return false, err
		}
		if c.value == "" {
			f.Log.Infof("No valid checksum found, skipping verification...")
			return true, nil
		}
		ok, _, err := c.verify(final)
		if err != nil {
			return false, err
		}
		if ok {
			f.Log.Infof("Checksum matched for %s", base)
			return true, nil
		}
		f.Log.Infof("Checksum mismatch for %s. Re-downloading...", base)
		if err := os.Remove(final); err != nil {
			return false, err
		}
	}

	if err := os.MkdirAll(a.path, 0o755); err != nil {
		return false, err
	}
	if fileExists(cached) {
		c, err := expected()
		if err != nil {
			return false, err
		}
		ok, _, err := c.verify(cached)
		if err != nil {
			return false, err
		}
		if ok {
			f.Log.Infof("Artifact %s-%s already present in cache, copying...", a.name, a.version)
			return true, copyFile(cached, final)
		}
		f.Log.Infof("Checksum mismatch for %s. Re-downloading...", base)
		if err := os.Remove(cached); err != nil {
			return false, err
		}
	}

	f.Log.Infof("Downloading %s:%s %s from %s", a.group, a.name, a.version, a.source.url)
	tmp, err := f.download(a, cacheDir)
	var he *httpError
	if errors.As(err, &he) && (he.code == http.StatusUnauthorized || he.code == http.StatusForbidden) {
		reason := "Invalid or missing credentials"
		if he.code == http.StatusForbidden {
			reason = "Forbidden access"
		}
		f.Log.Warnf("%s for %s-%s from source '%s', skipping...", reason, a.name, a.version, a.source.name)
		f.skipped = append(f.skipped, skipped{a.name, a.version, a.source.name, a.url(), he.code})
		return false, nil
	} else if err != nil {
		return false, err
	}
	defer os.Remove(tmp)

	c, err := expected()
	if err != nil {
		return false, err
	}
	ok, actual, err := c.verify(tmp)
	if err != nil {
		return false, err
	}
	if !ok {
		return false, fmt.Errorf("checksum mismatch for %s. Expected: %s, Computed: %s", base, c.value, actual)
	}
	if err := os.Rename(tmp, cached); err != nil {
		return false, err
	}
	return true, copyFile(cached, final)
}

func (f *Fetcher) download(a artifact, dir string) (string, error) {
	body, err := f.get(a.url(), a.source)
	if err != nil {
		return "", err
	}
	defer body.Close()
	out, err := os.CreateTemp(dir, ".download-*")
	if err != nil {
		return "", err
	}
	_, err = io.Copy(out, body)
	if cerr := out.Close(); err == nil {
		err = cerr
	}
	if err != nil {
		os.Remove(out.Name())
		return "", err
	}
	return out.Name(), nil
}

// cacheDir is keyed by source name and by a hash of its URL, so repointing a
// source to another repository never serves artifacts cached from the old one.
func (f *Fetcher) cacheDir(s *source) string {
	sum := sha1.Sum([]byte(s.url))
	return filepath.Join(f.Root, "artifacts_cache", s.name, hex.EncodeToString(sum[:])[:12])
}

// pruneStale removes other versions of a from its folder. The version must
// start with a digit so that name prefixes (foo vs foo-extra) don't collide.
func (f *Fetcher) pruneStale(a artifact, final string) {
	entries, err := os.ReadDir(a.path)
	if err != nil {
		return
	}
	pattern := regexp.MustCompile(`^` + regexp.QuoteMeta(a.name) + `-\d[^/\\]*` + regexp.QuoteMeta(a.classifier) + `$`)
	current := filepath.Base(final)
	for _, e := range entries {
		p := filepath.Join(a.path, e.Name())
		if e.Name() == current || f.fetched[p] || !e.Type().IsRegular() || !pattern.MatchString(e.Name()) {
			continue
		}
		if err := os.Remove(p); err != nil {
			f.Log.Warnf("Failed to remove stale artifact %s: %v", p, err)
			continue
		}
		f.Log.Infof("Removing stale artifact %s (superseded by %s)", p, current)
	}
}

func (f *Fetcher) printSkipped() {
	if len(f.skipped) == 0 {
		return
	}
	f.Log.Warnf("")
	f.Log.Warnf("Skipped %d artifact(s) due to authentication failures:", len(f.skipped))
	for _, s := range f.skipped {
		f.Log.Warnf("  - %s-%s (source '%s', HTTP %d): %s", s.name, s.version, s.source, s.code, s.url)
	}
}

func fileExists(p string) bool {
	info, err := os.Stat(p)
	return err == nil && info.Mode().IsRegular()
}

func copyFile(src, dst string) error {
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()
	out, err := os.Create(dst)
	if err != nil {
		return err
	}
	if _, err := io.Copy(out, in); err != nil {
		out.Close()
		return err
	}
	return out.Close()
}
