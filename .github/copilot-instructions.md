# Alfresco Dockerfiles Bakery

Builds the Alfresco platform container images (ACS, APS, ATS, search, connectors, ADF apps) from
release artifacts pulled off Alfresco's Nexus. There is no application source here — only
Dockerfiles, entrypoints, artifact manifests and the bake/make plumbing that assembles them.

## Commands

```sh
make help                       # list build targets
make enterprise                 # or: community, all, repository, share, aps, tengines, ...
make enterprise ACS_VERSION=23  # build an older line (see Versioning below)
make clean prepare ACS_VERSION=23   # always clean before switching versions
make clean_caches               # prune docker builder cache + artifacts_cache/

docker buildx bake tengine_imagemagick   # single image, bypassing make (no auth/fetch wrapper)
docker buildx bake repository --print    # resolved target config, useful for debugging HCL

bats -r --print-output-on-failure .              # full bats suite (as CI runs it)
bats scripts/tests/test_fetch_artifacts.bats     # single test file
pre-commit run --all-files                       # yaml/json/workflow-schema + checkmake

make grype GRYPE_TARGET=repository GRYPE_OPTS="-f high --only-fixed"
make all GRYPE_ONBUILD=1        # scan every image at the end of the build
```

Nexus credentials come from `~/.netrc` (`machine nexus.alfresco.com`, mode 0600) or
`NEXUS_USERNAME`/`NEXUS_PASSWORD`. Without them, Enterprise artifacts are skipped with a warning
rather than failing the run, so a "successful" build can silently be missing images.

Build env vars: `REGISTRY` (default `localhost`), `REGISTRY_NAMESPACE` (`alfresco`), `TAG`,
`TARGETARCH` (comma-separated list for multi-arch — requires pushing to a registry),
`BAKE_NO_CACHE`, `BAKE_NO_PROVENANCE`.

## Architecture

**`docker-bake.hcl` is the source of truth.** It declares every image target, its build context,
args, OCI labels and tags. The `Makefile` is a wrapper that adds three things bake cannot do:
registry login (with an interactive confirmation prompt), fetching artifacts before the build, and
optional Grype scanning. Each `make <component>` target therefore pairs a `prepare_<component>`
(fetch) with a `docker buildx bake <component>`.

**Two-phase build.** `scripts/fetch_artifacts.py` reads every `artifacts-<VERSION>.yaml`, downloads
each artifact from Nexus into the `path:` declared in the manifest (e.g. `repository/amps`,
`repository/distribution`), verifies the checksum, caches it in `artifacts_cache/`, and prunes
superseded versions of the same artifact from the target folder. The Dockerfiles then pull those
files into the build. All downloaded binaries are gitignored — the folders under each component
contain only a placeholder `README.md`.

**Build inputs as named contexts.** `repository` reads each of its build inputs through a named
context (`repo_distribution`, `repo_amps`, `repo_amps_edition`, `repo_libs`, `repo_simple_modules`)
declared in `docker-bake.hcl`, defaulting to the folder it replaces and consumed with
`COPY --from=<context> / <dest>`. A consumer can then repoint an input at a directory of their own
with `cwd://` and build against a remote bake definition, so customizing an image needs no fork of
this repository. Overriding a context *replaces* that folder rather than merging with it. The other
components still `COPY` straight from their own build context; converting them follows the
`repository` pattern.

**Base image chain.** `java_base` (`./java`) → `tomcat_base` (`./tomcat`) → webapp images
(`repository`, `share`, `aps-*`). Everything else inherits `java_base` directly. Both bases are
`output = ["type=cacheonly"]` and are wired in as named build contexts
(`contexts = { java_base = "target:java_base" }`), which is why component Dockerfiles start with
`FROM java_base` / `FROM tomcat_base` — those are bake contexts, not registry images, and such a
Dockerfile cannot be built with plain `docker build`.

**Distro dispatch.** Dockerfiles select the final stage through arg interpolation:
`FROM <name>-rhlike AS ...` / `FROM <name>-rockylinux9` / `FROM <name>-${DISTRIB_NAME}${DISTRIB_MAJOR}`.
Adding OS support means adding a stage alias, not branching in `RUN`.

**Versioning.** `ACS_VERSION` (default 26) and `APS_VERSION` pick which `artifacts-XX.yaml` files
are read, for both fetching and tagging. `docker-bake.hcl` derives the rest from `ACS_VERSION`:
`select_java_version` and `select_tomcat_field` map 23/25 → Java 17 + Tomcat 10, anything else →
Java 21 + Tomcat 11. Tomcat versions and SHA512s live in the `TOMCAT_VERSIONS` map in the HCL.

**Tags come from artifact versions, not `latest`.** The Makefile exports `ARTIFACT_VERSIONS`, a JSON
map produced by `scripts/print_artifact_versions.py`, and the `image_tag(artifact)` HCL function
looks the version up per target. Setting `TAG` overrides this for all images.

## Conventions

- Every service runs as a dedicated non-root user; the numeric UID/GID are `variable` blocks in
  `docker-bake.hcl` (shared `ALFRESCO_GROUP_ID` 1000, per-service UIDs in the 330xx range) passed
  through as build args. Keep them stable — they are load-bearing for volume permissions.
- Spring Boot services ship a two-line `entrypoint.sh`: `exec java $JAVA_OPTS
  $JAVA_OPTS_CONTAINER_FLAGS -jar /opt/app.jar`.
- `artifacts-XX.yaml` entries need `name`, `version`, `group`, `repository` (Nexus repo:
  `public`/`releases`/`enterprise-releases`), `path` (destination dir), `classifier` (the file
  extension, e.g. `".jar"`), and `checksum` as `<algo>:` — leaving the hash empty makes the script
  fetch `<url>.<algo>` from Nexus.
- Automated version bumps are driven by updatecli (`.github/updatecli*.tpl`, weekly
  `bumpVersions.yml`). An artifact is only bumped if it has an `updatecli_matrix_component_key`
  entry in `.github/updatecli_values.yaml`; AMP bumps additionally need
  `updatecli_amps_release_branch` in the manifest.
- Adding a component: create the folder (Dockerfile, `entrypoint.sh`, `artifacts-XX.yaml` per
  supported version), add a `target` and put it in the right `group` in `docker-bake.hcl`, declare
  its build inputs as named contexts, add a `prepare_<x>` and a build target in the `Makefile` (both
  blocks are kept alphabetical), and add it to the `test-make.yml` matrix.
- Named context names, target names, build args and UIDs are the interface consumers build against.
  Renaming one breaks overlays that never appear in this repository.
- `checkmake` caps Makefile recipe bodies at 22 lines (`checkmake.ini`); factor longer logic into
  `scripts/`.
- Dockerfile findings suppressed on purpose are listed with a rationale in `kics.config`; Grype
  ignores `java-archive` packages (`.grype.yaml`) because the focus is base-OS CVEs.

## CI

`build_and_test.yml` runs pre-commit, then a matrix of ACS 26/25/23 and APS 26/25/24 through the
reusable workflows, each of which bakes the images to ghcr.io and then validates them twice: a
docker compose run driven by a Postman collection, and a Helm install into KinD (amd64 + arm64)
followed by `helm test`. Compose files and Helm values are pulled from the `acs-deployment` repo at
runtime; only the override files in `test/` are versioned here. `test-make.yml` separately checks
that each `make` target still builds and loads images locally.
