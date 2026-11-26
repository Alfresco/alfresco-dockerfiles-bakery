# AGENTS.md

This file provides guidance to AI coding agents (Claude Code, GitHub Copilot, Codex, etc.) when working with
code in this repository.

## What this is

Alfresco Dockerfiles Bakery: Docker Bake definitions and Dockerfiles that build container images for the
Alfresco Content Services (ACS) and Alfresco Process Services (APS) platforms (repository, share, search,
transform engines, sync, connectors, audit storage, etc). `docker-bake.hcl` is the single source of truth
for every image target; the `bakery` Go CLI (its own Go module in `cli`) wraps `docker buildx bake` and adds
artifact fetching, registry auth/push confirmation, cleanup, and optional Grype scanning.

## Commands

```sh
cd cli && go install ./bakery              # or `go run ./bakery <command>` from cli

bakery build community                          # build all Community edition images locally
bakery build enterprise                         # build all Enterprise edition images locally
bakery build --help                             # list all build targets and options
bakery build repository                         # build only the Repository image (also: share, tengines, aps, ats, sync, ...)
bakery clean -f                                 # remove fetched Nexus artifacts
bakery clean --caches                           # prune docker build cache + artifacts_cache/

bakery build enterprise --acs-version 23        # build a specific ACS version (26 is default; 23/25/26 supported)
bakery build aps --aps-version 26               # build a specific APS version
bakery build share --registry quay.io --yes     # push instead of loading locally (no confirmation prompt)

docker buildx bake <target>                     # bake a target directly, bypassing the CLI
ARTIFACT_VERSIONS="$(bakery versions)" docker buildx bake <target> --print   # inspect resolved config/tags
docker buildx bake repository --set repository.contexts.repo_libs=./custom-libs   # override a named build context

bakery fetch [targets...]                       # fetch artifacts standalone (build runs this per target)
bakery fetch repository --log-level DEBUG

./test/verify.sh                                # run all image tests (auto-discovers */tests/*_test.sh)

bakery grype repository                         # manual vuln scan (default opts: -f high --only-fixed --ignore-states wont-fix)

(cd cli && go vet ./... && go test ./...)   # CLI tests
```

Building requires Docker with `buildx` and the `bakery` CLI (a release binary, or Go to build it). Every option
also reads the environment variable the old Makefile used (`ACS_VERSION`, `REGISTRY`, `BAKE_NO_CACHE`, ...).
Nexus credentials (for Enterprise artifacts) go in `~/.netrc` for `machine nexus.alfresco.com` (one entry per
source host). The `Vagrantfile` provisions a VM with all of this preinstalled as an alternative to a local
toolchain.

Image tests are the `*_test.sh` scripts under each image's `tests/` directory, run against real built images
by `./test/verify.sh` (see `TESTING.md`) — to add one, drop an executable `<image>/tests/*_test.sh` that takes
the resolved image ref as `$1` and exits non-zero on failure. The CLI has Go tests, run by
`.github/workflows/cli.yml`: most live in `cli/bakery` and run the real binary against a scratch checkout
with a mock Maven repository (`httptest`) and fake `docker`/`grype` scripts on `PATH` that log their argv
and env; add a case there for any CLI behaviour change. `cli/internal/artifacts/repo_test.go` checks every
manifest in this repo against the legacy Nexus URL layout, and `cli/internal/bake/targets_test.go` checks the
CLI `targets` table against `docker buildx bake --print` (skipped when buildx is missing).

Pre-commit hooks (`.pre-commit-config.yaml`) check YAML/JSON/XML validity and GitHub workflow schemas
(`check-github-workflows`), and for changes under `cli/` run `gofmt`, `go mod tidy -diff` and `go vet` (local
hooks, so they need Go installed). KICS (`kics.config`) and Grype
(`.grype.yaml`) scan for IaC and container vulnerabilities respectively in CI.

## Architecture

**Bake target graph.** Every image is a `target` block in `docker-bake.hcl`. `java_base` (OS + a headless JRE,
`docker.io/rockylinux/rockylinux:9-minimal` by default) is the root of the graph and is `output =
["type=cacheonly"]` — it never produces a runnable image on its own, only cache layers other targets build on.
Most targets inherit from it directly (`search_batch_indexing`, `search_service`, `sync`, the transform
engines, ...); Tomcat-based ones (`repository`, `share`) go through the intermediate `tomcat_base`, also
cache-only, which adds Tomcat selected per ACS version. A few targets (`acc`, `adw`, the ADF apps) don't
inherit from either and build from their own Nginx-based Dockerfile instead. `test/verify.sh` knows to
redirect tests for cache-only targets to the first real target that inherits from them. Targets are grouped
(`group "enterprise"`, `group "community"`, etc.). The CLI's build targets (the `targets` table in
`cli/internal/bake/bake.go`) map 1:1 to these groups, each with the folders or glob it fetches artifacts from;
`bakery build` fetches them, runs `docker buildx bake`, then an optional Grype scan. Add a row there when
adding a new top-level group.

**ACS/APS version switching.** `ACS_VERSION` (23/25/26, default 26) drives which `artifacts-XX.yaml` files get
read for ACS components and which Tomcat/Java version bake selects (`select_java_version`,
`select_tomcat_field` in `docker-bake.hcl`; JDK 17 for ACS 23/25, 21 for 26). Community search also branches on
version: ACS 23/25/26.0/26.1 build `search_service` (Solr), 26.2+ build `search_batch_indexing`
(Elasticsearch) — see `select_community_search()`. `APS_VERSION` is independent of `ACS_VERSION`: it selects
which `aps/**/artifacts-XX.yaml` files get fetched (and, through `bakery versions` /
`ARTIFACT_VERSIONS`, which artifact versions APS image tags resolve to), but has no effect on Java/Tomcat
selection.

**Artifacts pipeline.** Each image directory that needs external binaries has one or more `artifacts-XX.yaml`
files declaring Maven coordinates, version, checksum, a `source`, and destination `path`. Each `source` is a
named Maven repository root defined in the committed `sources.yaml`; credentials are never stored there but
resolved per source, by host, from `~/.netrc` (anonymous when none), so a build can mix multiple repositories.
Third parties can repoint these at their own repositories — see `docs/bring-your-own-repository.md`.
`bakery fetch` (`cli/internal/artifacts`) walks the repo for `artifacts-*.yaml` (or a given target/glob, skipping
hidden folders) and downloads each
artifact into that image's build context (e.g. `repository/amps`, `repository/libs`) from its source's base URL
using the standard Maven GAV layout, caching per source under `artifacts_cache/<source>/`. A missing/unknown
source (or a leftover `repository` key) fails fast; a `401`/`403` skips the artifact and is reported in an
end-of-run summary. It verifies the checksum when the manifest declares
one (some manifests, e.g. `search/community/artifacts-26.yaml`, omit it, in which case verification is skipped
with a logged warning), and prunes stale versions of the same artifact automatically.
`bakery versions` (passed to bake as `ARTIFACT_VERSIONS` by `bakery build`) turns those same YAML files into the version map that `image_tag()` in `docker-bake.hcl`
uses to tag images — so an image's tag is normally the version of the Alfresco artifact it packages, not
`TAG`/`latest`, unless `TAG` is explicitly set.

**Customization via named build contexts.** Images that support user customization (Repository, Share) expose
named contexts in their bake target (e.g. `repo_amps`, `repo_amps_edition`, `repo_libs`,
`repo_simple_modules`, `share_amps`, `share_simple_modules`) that default to folders in this repo
(`repository/amps`, `repository/libs`, ...) but can be redirected with `docker buildx bake <target>
--set <target>.contexts.<name>=<path>` to point at a different directory, without editing the Dockerfile.

**Directory layout convention.** Top-level product folders (repository, share, search, tengine, sync, ats,
audit-storage, connector, cic-connector, adf-apps, aps, java, tomcat) group one or more images. Simple ones
(repository, share, java, tomcat) hold their `Dockerfile`, `artifacts-XX.yaml` and `tests/` directly; others
nest per-component subdirectories with their own `Dockerfile`/`artifacts-XX.yaml`/`tests/` (e.g.
`search/community`, `ats/sfs`, `aps/admin`) — not every folder has all three, and not every image has tests.
Most image directories also carry a `README.md` documenting their specific customization points; read it
before changing that image's Dockerfile. `artifacts_cache/` is the (gitignored, checked-in placeholder)
download cache used by `bakery fetch`; don't hand-edit its contents.

**CI.** `.github/workflows/build_and_test.yml` is the main pipeline: pre-commit, then matrixed ACS builds (26,
25, 23) via `acs_reusable_build_and_test.yml` and APS builds via `aps_reusable_build_and_test.yml`, both
wrapping `reusable_bake_build.yml`. `build_forks.yml` is a reduced, no-secrets path for PRs from forks: it
builds only the Community ACS 26 target with `bakery build community`, then runs compose and Helm smoke tests against it — it does not cover
the full ACS/APS version matrix. `bumpVersions.yml` runs updatecli to bump artifact/base-image versions. The `thirdparty` job (`.github/updatecli_thirdparty.tpl`, values in `.github/updatecli_thirdparty_values.yaml`) is a matrix with one pipeline per component (`COMPONENT`), so ImageMagick and LibreOffice each get their own PR. It bumps the repackaged distribution in every `tengine/{imagemagick,libreoffice}/artifacts-*.yaml` to the newest Nexus version by `sort -V`, once all its classifiers are published.
`grype-scan.yml` and `kics.yml` run security scanning. Workflows get the CLI through the
`.github/actions/setup-bakery` composite action, which builds it from the checkout. `cli.yml` tests the CLI
and smoke-builds every target with it (skipped on fork PRs). Release process is documented at the bottom of `README.md`;
publishing a release runs `on-release.yml`, which attaches the GoReleaser binaries (`cli/.goreleaser.yaml`) to
that release.
