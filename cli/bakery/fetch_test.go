package main

import (
	"crypto/sha1"
	"encoding/hex"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func sourcesFor(urls ...string) string {
	s := "sources:\n"
	for i := 0; i+1 < len(urls); i += 2 {
		s += "  " + urls[i] + ":\n    url: " + urls[i+1] + "\n"
	}
	return s
}

func TestFetchAuthenticatedSource(t *testing.T) {
	f := newFixture(t)
	r := newMavenRepo(t, "alice", "secret")
	r.seed(t, "com.test", "test-artifact", "1.0.0", ".jar", "")
	f.netrc("machine 127.0.0.1\n  login alice\n  password secret\n")
	f.write("sources.yaml", sourcesFor("mocksrc", r.URL))
	f.write("t/artifacts-26.yaml", manifest(artifact("test-artifact", "1.0.0", "com.test", "mocksrc", "t/libs")))

	res := f.run("", "fetch", "t")
	if res.code != 0 || !f.exists("t/libs/test-artifact-1.0.0.jar") {
		t.Fatal("artifact not fetched")
	}
}

func TestFetchAnonymousWithoutNetrc(t *testing.T) {
	f := newFixture(t)
	r := newMavenRepo(t, "", "")
	r.seed(t, "com.test", "anon-artifact", "2.0.0", ".jar", "")
	f.write("sources.yaml", sourcesFor("mocksrc", r.URL))
	f.write("t/artifacts-26.yaml", manifest(artifact("anon-artifact", "2.0.0", "com.test", "mocksrc", "t/libs")))

	res := f.run("", "fetch", "t")
	if res.code != 0 || !f.exists("t/libs/anon-artifact-2.0.0.jar") {
		t.Fatal("artifact not fetched")
	}
}

func TestFetchSkips401And403WithSummary(t *testing.T) {
	f := newFixture(t)
	r := newMavenRepo(t, "alice", "secret")
	r.seed(t, "com.test", "authed-artifact", "1.2.3", ".jar", "")
	r.seed(t, "com.forbidden", "blocked-artifact", "3.0.0", ".jar", "")
	f.netrc("machine 127.0.0.1\n  login alice\n  password WRONG\n")
	f.write("sources.yaml", sourcesFor("mocksrc", r.URL))
	f.write("t/artifacts-26.yaml", manifest(
		artifact("authed-artifact", "1.2.3", "com.test", "mocksrc", "t/libs"),
		artifact("blocked-artifact", "3.0.0", "com.forbidden", "mocksrc", "t/libs"),
	))

	res := f.run("", "fetch", "t")
	if res.code != 0 {
		t.Fatal("auth failures must not fail the run")
	}
	if f.exists("t/libs/authed-artifact-1.2.3.jar") || f.exists("t/libs/blocked-artifact-3.0.0.jar") {
		t.Error("skipped artifacts must not be written")
	}
	assertContains(t, res.out, "Skipped 2 artifact(s) due to authentication failures")
	assertContains(t, res.out, "authed-artifact-1.2.3 (source 'mocksrc', HTTP 401)")
	assertContains(t, res.out, "blocked-artifact-3.0.0 (source 'mocksrc', HTTP 403)")
}

func TestFetchCredentialsIsolatedPerHost(t *testing.T) {
	f := newFixture(t)
	a := newMavenRepo(t, "userA", "passA")
	b := newMavenRepo(t, "userB", "passB")
	a.seed(t, "com.test", "artifact-a", "1.0.0", ".jar", "")
	b.seed(t, "com.test", "artifact-b", "1.0.0", ".jar", "")
	f.netrc("machine 127.0.0.1\n  login userA\n  password passA\nmachine localhost\n  login userB\n  password passB\n")
	f.write("sources.yaml", sourcesFor("source_a", a.URL, "source_b", strings.Replace(b.URL, "127.0.0.1", "localhost", 1)))
	f.write("t/artifacts-26.yaml", manifest(
		artifact("artifact-a", "1.0.0", "com.test", "source_a", "t/libs"),
		artifact("artifact-b", "1.0.0", "com.test", "source_b", "t/libs"),
	))

	res := f.run("", "fetch", "t")
	if res.code != 0 || !f.exists("t/libs/artifact-a-1.0.0.jar") || !f.exists("t/libs/artifact-b-1.0.0.jar") {
		t.Fatal("artifacts not fetched")
	}
	assertContains(t, a.log(), basicAuth("userA", "passA"))
	assertNotContains(t, a.log(), basicAuth("userB", "passB"))
	assertContains(t, b.log(), basicAuth("userB", "passB"))
	assertNotContains(t, b.log(), basicAuth("userA", "passA"))
}

func TestFetchIgnoresNetrcDefault(t *testing.T) {
	f := newFixture(t)
	r := newMavenRepo(t, "", "")
	r.seed(t, "com.test", "default-artifact", "1.0.0", ".jar", "")
	f.netrc("default\n  login defuser\n  password defpass\n")
	f.write("sources.yaml", sourcesFor("mocksrc", r.URL))
	f.write("t/artifacts-26.yaml", manifest(artifact("default-artifact", "1.0.0", "com.test", "mocksrc", "t/libs")))

	res := f.run("", "fetch", "t")
	if res.code != 0 || !f.exists("t/libs/default-artifact-1.0.0.jar") {
		t.Fatal("artifact not fetched")
	}
	assertNotContains(t, r.log(), "Basic ")
}

func TestFetchCachesPerSourceURL(t *testing.T) {
	f := newFixture(t)
	r := newMavenRepo(t, "", "")
	r.seed(t, "com.test", "cached-artifact", "9.9.9", ".jar", "")
	f.write("sources.yaml", sourcesFor("cachesrc", r.URL))
	f.write("t/artifacts-26.yaml", manifest(artifact("cached-artifact", "9.9.9", "com.test", "cachesrc", "t/libs")))

	if res := f.run("", "fetch", "t"); res.code != 0 {
		t.Fatal("fetch failed")
	}
	sum := sha1.Sum([]byte(r.URL))
	tag := hex.EncodeToString(sum[:])[:12]
	if !f.exists(filepath.Join("artifacts_cache", "cachesrc", tag, "cached-artifact-9.9.9.jar")) {
		t.Fatal("artifact not cached under artifacts_cache/<source>/<sha1(url)[:12]>")
	}

	// A second fetch is served from the cache.
	must(t, os.Remove(filepath.Join(f.root, "t/libs/cached-artifact-9.9.9.jar")))
	before := len(strings.Split(r.log(), "\n"))
	res := f.run("", "fetch", "t")
	assertContains(t, res.out, "already present in cache")
	if after := len(strings.Split(r.log(), "\n")); after != before {
		t.Error("cached artifact was downloaded again")
	}
}

func TestFetchRepointedSourceSkipsStaleCache(t *testing.T) {
	f := newFixture(t)
	a := newMavenRepo(t, "", "")
	b := newMavenRepo(t, "", "")
	a.seed(t, "com.test", "moving-artifact", "1.0.0", ".jar", "from-a\n")
	b.seed(t, "com.test", "moving-artifact", "1.0.0", ".jar", "from-b\n")
	f.write("t/artifacts-26.yaml", manifest(artifact("moving-artifact", "1.0.0", "com.test", "movingsrc", "t/libs")))

	f.write("sources.yaml", sourcesFor("movingsrc", a.URL))
	if res := f.run("", "fetch", "t"); res.code != 0 {
		t.Fatal("first fetch failed")
	}
	must(t, os.Remove(filepath.Join(f.root, "t/libs/moving-artifact-1.0.0.jar")))
	f.write("sources.yaml", sourcesFor("movingsrc", b.URL))
	if res := f.run("", "fetch", "t"); res.code != 0 {
		t.Fatal("second fetch failed")
	}
	got, err := os.ReadFile(filepath.Join(f.root, "t/libs/moving-artifact-1.0.0.jar"))
	must(t, err)
	if string(got) != "from-b\n" {
		t.Errorf("served %q, want the repointed source's bytes", got)
	}
}

func TestFetchFailsFastOnBadSource(t *testing.T) {
	cases := map[string]struct{ entry, want string }{
		"unknown source": {artifact("mystery", "1.0.0", "com.test", "nope", "t/libs"), "unknown source 'nope'"},
		"no source":      {artifact("mystery", "1.0.0", "com.test", "", "t/libs"), "has no 'source'"},
		"repository key": {artifact("legacy", "1.0.0", "com.test", "", "t/libs", "repository: known"), "removed 'repository' field"},
	}
	for name, c := range cases {
		t.Run(name, func(t *testing.T) {
			f := newFixture(t)
			f.write("sources.yaml", sourcesFor("known", "http://127.0.0.1:1"))
			f.write("t/artifacts-26.yaml", manifest(c.entry))
			res := f.run("", "fetch", "t")
			if res.code == 0 {
				t.Fatal("expected failure")
			}
			assertContains(t, res.out, c.want)
		})
	}
}

func TestFetchQuotedNetrcCredentials(t *testing.T) {
	cases := map[string]string{
		"quoted":  "machine 127.0.0.1\n  login \"alice\"\n  password \"secret value\"\n",
		"escaped": "machine 127.0.0.1 login alice password secret\\ value\n",
	}
	for name, netrc := range cases {
		t.Run(name, func(t *testing.T) {
			f := newFixture(t)
			r := newMavenRepo(t, "alice", "secret value")
			r.seed(t, "com.test", "quoted-artifact", "1.0.0", ".jar", "")
			f.netrc(netrc)
			f.write("sources.yaml", sourcesFor("mocksrc", r.URL))
			f.write("t/artifacts-26.yaml", manifest(artifact("quoted-artifact", "1.0.0", "com.test", "mocksrc", "t/libs")))

			res := f.run("", "fetch", "t")
			if res.code != 0 || !f.exists("t/libs/quoted-artifact-1.0.0.jar") {
				t.Fatal("artifact not fetched with quoted credentials")
			}
		})
	}
}

func TestFetchNeverLogsCredentials(t *testing.T) {
	f := newFixture(t)
	r := newMavenRepo(t, "secretuser", "s3cr3t-value")
	r.seed(t, "com.test", "nolog-artifact", "1.0.0", ".jar", "")
	f.netrc("machine 127.0.0.1\n  login secretuser\n  password s3cr3t-value\n")
	f.write("sources.yaml", sourcesFor("mocksrc", r.URL))
	f.write("t/artifacts-26.yaml", manifest(artifact("nolog-artifact", "1.0.0", "com.test", "mocksrc", "t/libs")))

	res := f.run("", "fetch", "t", "--log-level", "DEBUG")
	if res.code != 0 || !f.exists("t/libs/nolog-artifact-1.0.0.jar") {
		t.Fatal("artifact not fetched")
	}
	assertNotContains(t, res.out, "s3cr3t-value")
	assertNotContains(t, res.out, "secretuser")
}

func TestFetchVerifiesChecksums(t *testing.T) {
	f := newFixture(t)
	r := newMavenRepo(t, "", "")
	content := r.seed(t, "com.test", "summed", "1.0.0", ".jar", "")
	sum := sha1.Sum([]byte(content))
	hexsum := hex.EncodeToString(sum[:])
	// Remote checksum file, used when the manifest declares "sha1:" with no value.
	must(t, os.WriteFile(filepath.Join(r.dir, "com/test/summed/1.0.0/summed-1.0.0.jar.sha1"), []byte(hexsum+"\n"), 0o644))
	r.seed(t, "com.test", "tampered", "1.0.0", ".jar", "")
	f.write("sources.yaml", sourcesFor("mocksrc", r.URL))

	f.write("a/artifacts-26.yaml", manifest(artifact("summed", "1.0.0", "com.test", "mocksrc", "a/libs", `checksum: "sha1:"`)))
	if res := f.run("", "fetch", "a"); res.code != 0 || !f.exists("a/libs/summed-1.0.0.jar") {
		t.Fatal("remote checksum verification failed")
	}
	f.write("b/artifacts-26.yaml", manifest(artifact("summed", "1.0.0", "com.test", "mocksrc", "b/libs", `checksum: "sha1:`+hexsum+`"`)))
	if res := f.run("", "fetch", "b"); res.code != 0 || !f.exists("b/libs/summed-1.0.0.jar") {
		t.Fatal("inline checksum verification failed")
	}
	f.write("c/artifacts-26.yaml", manifest(artifact("tampered", "1.0.0", "com.test", "mocksrc", "c/libs", `checksum: "sha256:0000"`)))
	res := f.run("", "fetch", "c")
	if res.code == 0 || f.exists("c/libs/tampered-1.0.0.jar") {
		t.Fatal("checksum mismatch must fail without writing the artifact")
	}
	assertContains(t, res.out, "checksum mismatch for tampered-1.0.0.jar")
}

func TestFetchPrunesStaleVersions(t *testing.T) {
	f := newFixture(t)
	f.write("t/libs/test-artifact-1.0.0.jar", "")
	f.write("t/libs/test-artifact-2.0.0.jar", "")
	f.write("t/libs/test-artifact-extra-1.0.0.jar", "")
	f.write("t/artifacts-26.yaml", manifest(artifact("test-artifact", "2.0.0", "com.test", "public", "t/libs")))

	res := f.run("", "fetch", "t", "--log-level", "DEBUG")
	if res.code != 0 {
		t.Fatal("fetch failed")
	}
	assertContains(t, res.out, "Removing stale artifact")
	if f.exists("t/libs/test-artifact-1.0.0.jar") {
		t.Error("stale version not removed")
	}
	if !f.exists("t/libs/test-artifact-2.0.0.jar") || !f.exists("t/libs/test-artifact-extra-1.0.0.jar") {
		t.Error("current version or prefix-sharing artifact removed")
	}

	res = f.run("", "fetch", "t")
	assertNotContains(t, res.out, "Removing stale artifact")
}

func TestFetchTargetSelection(t *testing.T) {
	f := newFixture(t)
	r := newMavenRepo(t, "", "")
	for _, n := range []string{"one", "two", "old", "glob", "aps"} {
		r.seed(t, "com.test", n, "1.0.0", ".jar", "")
	}
	f.write("sources.yaml", sourcesFor("mocksrc", r.URL))
	f.write("one/artifacts-26.yaml", manifest(artifact("one", "1.0.0", "com.test", "mocksrc", "one/libs")))
	f.write("two/nested/artifacts-26.yaml", manifest(artifact("two", "1.0.0", "com.test", "mocksrc", "two/libs")))
	f.write("one/artifacts-25.yaml", manifest(artifact("old", "1.0.0", "com.test", "mocksrc", "one/libs")))
	f.write("g/artifacts-26-uncommon.yaml", manifest(artifact("glob", "1.0.0", "com.test", "mocksrc", "g/libs")))
	f.write("aps/x/artifacts-24.yaml", manifest(artifact("aps", "1.0.0", "com.test", "mocksrc", "aps/libs")))
	f.write(".hidden/artifacts-26.yaml", "not: [valid")

	res := f.run("", "fetch", "one", "two", "--log-level", "DEBUG")
	assertContains(t, res.out, "Processing target: one")
	assertContains(t, res.out, "Processing target: two")
	if !f.exists("one/libs/one-1.0.0.jar") || !f.exists("two/libs/two-1.0.0.jar") {
		t.Error("directory targets not fetched")
	}
	if f.exists("one/libs/old-1.0.0.jar") {
		t.Error("manifest for another ACS version fetched")
	}

	res = f.run("", "fetch", "**/artifacts-*-uncommon.yaml", "aps/**/artifacts-24.yaml", "--log-level", "DEBUG")
	assertContains(t, res.out, "glob pattern")
	if res.code != 0 || !f.exists("g/libs/glob-1.0.0.jar") || !f.exists("aps/libs/aps-1.0.0.jar") {
		t.Error("glob targets not fetched")
	}

	res = f.run("", "fetch", "--acs-version", "25")
	if res.code != 0 || !f.exists("one/libs/old-1.0.0.jar") {
		t.Error("no-argument fetch for ACS 25 did not cover the whole repo")
	}

	res = f.run("", "fetch", "**/nonexistent-*.yaml")
	if res.code != 0 {
		t.Error("a glob matching nothing must not fail")
	}
}

func TestFetchBrokenManifestFails(t *testing.T) {
	f := newFixture(t)
	f.write("t/artifacts-26.yaml", "this is not yaml at all!!!\nrandom text [[[\n")
	res := f.run("", "fetch", "t")
	if res.code == 0 {
		t.Fatal("broken manifest must fail")
	}
	assertContains(t, res.out, "artifacts-26.yaml")
}
