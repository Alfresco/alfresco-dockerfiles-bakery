# AGENTS.md

This file provides guidance to AI coding agents (Claude Code, GitHub Copilot, Codex, etc.) when working with
code in this repository.

## What this is

Alfresco Dockerfiles Bakery: Docker Bake definitions and Dockerfiles that build container images for the
Alfresco Content Services (ACS) and Alfresco Process Services (APS) platforms (repository, share, search,
transform engines, sync, connectors, audit storage, etc). `docker-bake.hcl` is the single source of truth
for every image target; the `Makefile` is a thin wrapper around `docker buildx bake` that adds artifact
fetching, registry auth/push, and optional Grype scanning.

## Commands

```sh
make community                 # build all Community edition images locally
make enterprise                # build all Enterprise edition images locally
make help                      # list all make targets
make repository                # build only the Repository image (also: share, tengines, aps, ats, sync, ...)
make clean                     # remove fetched Nexus artifacts
make clean_caches              # prune docker build cache + artifacts_cache/

make enterprise ACS_VERSION=23                  # build a specific ACS version (26 is default; 23/25/26 supported)
make aps APS_VERSION=26                          # build a specific APS version

docker buildx bake <target>                     # bake a target directly, bypassing the make wrapper
docker buildx bake <target> --print              # inspect resolved config/tags for a target without building
docker buildx bake repository --set repository.contexts.repo_libs=./custom-libs   # override a named build context

python3 scripts/fetch_artifacts.py [targets...]  # fetch artifacts standalone (make calls this via prepare_*)
python3 scripts/fetch_artifacts.py repository --log-level DEBUG

./test/verify.sh                                 # run all image tests (auto-discovers */tests/*_test.sh)

make grype GRYPE_TARGET=repository GRYPE_OPTS="-f high --only-fixed --ignore-states wont-fix"  # manual vuln scan
```

Building requires Docker with `buildx`, plus `jq`, `yq`, `make`, and Python 3 with `pyyaml`. Nexus credentials
(for Enterprise artifacts) go in `~/.netrc` for `machine nexus.alfresco.com`. The `Vagrantfile` provisions a VM
with all of this preinstalled as an alternative to a local toolchain.

There is no unit test suite for application code — this repo's "tests" are the `*_test.sh` scripts under each
image's `tests/` directory, run against real built images by `./test/verify.sh` (see `TESTING.md`). To add a
test for an image, drop an executable `<image>/tests/*_test.sh` that takes the resolved image ref as `$1` and
exits non-zero on failure.

Pre-commit hooks (`.pre-commit-config.yaml`) check YAML/JSON/XML validity, GitHub workflow schemas
(`check-github-workflows`), and `Makefile` quality (`checkmake`, configured via `checkmake.ini`). KICS
(`kics.config`) and Grype (`.grype.yaml`) scan for IaC and container vulnerabilities respectively in CI.

## Architecture

**Bake target graph.** Every image is a `target` block in `docker-bake.hcl`, composed by inheritance:
`java_base` (OS + JDK, `docker.io/rockylinux/rockylinux:9-minimal` by default) → `tomcat_base` (adds Tomcat,
selected per ACS version) → per-application targets (`repository`, `share`, ...) that `inherit` from those and
add their own build context and Dockerfile. `java_base` and `tomcat_base` are `output = ["type=cacheonly"]` —
they never produce a runnable image on their own, only cache layers other targets build on; `test/verify.sh`
knows to redirect tests for such cache-only targets to the first real target that inherits from them.
Targets are grouped (`group "enterprise"`, `group "community"`, etc.) and the `Makefile` targets map 1:1 to
these groups/targets, in each case running `prepare_*` (artifact fetch) then `docker buildx bake` then an
optional Grype scan.

**ACS/APS version switching.** `ACS_VERSION` (23/25/26, default 26) drives which `artifacts-XX.yaml` files get
read for ACS components and which Tomcat/Java version bake selects (`select_java_version`,
`select_tomcat_field` in `docker-bake.hcl`; JDK 17 for ACS 23/25, 21 for 26). Community search also branches on
version: ACS 23/25/26.0/26.1 build `search_service` (Solr), 26.2+ build `search_batch_indexing`
(Elasticsearch) — see `select_community_search()`. `APS_VERSION` is independent and only selects which
`aps/**/artifacts-XX.yaml` files get fetched for the APS targets; it has no effect on Java/Tomcat selection.

**Artifacts pipeline.** Each image directory that needs external binaries has one or more `artifacts-XX.yaml`
files declaring Maven/Nexus coordinates, version, checksum, and destination `path`. `scripts/fetch_artifacts.py`
walks the repo for `artifacts-*.yaml` (or a given target/glob) and downloads each artifact into that image's
build context (e.g. `repository/amps`, `repository/libs`). It verifies the checksum when the manifest declares
one (some manifests, e.g. `search/community/artifacts-26.yaml`, omit it, in which case verification is skipped
with a logged warning), and prunes stale versions of the same artifact automatically.
`scripts/print_artifact_versions.py` (invoked by the `Makefile` into
`ARTIFACT_VERSIONS`) turns those same YAML files into the version map that `image_tag()` in `docker-bake.hcl`
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
download cache used by `fetch_artifacts.py`; don't hand-edit its contents.

**CI.** `.github/workflows/build_and_test.yml` is the main pipeline: pre-commit, then matrixed ACS builds (26,
25, 23) via `acs_reusable_build_and_test.yml` and APS builds via `aps_reusable_build_and_test.yml`, both
wrapping `reusable_bake_build.yml`. `build_forks.yml` is a reduced, no-secrets path for PRs from forks: it
builds only the Community ACS 26 target, then runs compose and Helm smoke tests against it — it does not cover
the full ACS/APS version matrix. `bumpVersions.yml` runs updatecli to bump artifact/base-image versions.
`grype-scan.yml` and `kics.yml` run security scanning. Release process is documented at the bottom of
`README.md`.
