# Security scanning baseline

Reference point for Grype results, so a future base image or dependency change
can be compared against something known. Recorded when the default base image
moved from `docker.io/rockylinux/rockylinux:9` to `:9-minimal` (OPSEXP-4315).

Measured 2026-09-17 with Grype v0.118.0 and DB v6.1.9 (built 2026-09-16),
`ACS_VERSION=26`, on `linux/arm64`. Both sides built from `f3b113f` with only
`IMAGE_BASE_LOCATION` varied and `GRYPE_DB_AUTO_UPDATE=false`, so the base image
tag is the single variable:

```sh
TAG=before IMAGE_BASE_LOCATION=docker.io/rockylinux/rockylinux:9 make repository tengines
TAG=after make repository tengines
TAG=<side> make grype GRYPE_TARGET=<target> GRYPE_OUTPUT_DIR=scan/<side> \
  GRYPE_OUTPUT_FORMAT=json GRYPE_OPTS="--only-fixed --ignore-states wont-fix"
```

`make grype` re-resolves tags via `docker buildx bake --print`, so the scan needs
the same `TAG`/`IMAGE_BASE_LOCATION` as the build.

## Result

Unique CVEs roughly halved, image size fell about a tenth, and the gated finding
count — `--only-fixed --ignore-states wont-fix`, what the weekly workflow uploads
— did not change at all.

| Image | rpms | Size | Gated CVEs | Total CVEs |
| --- | --- | --- | --- | --- |
| `alfresco-content-repository` | 181 → 156 | 890 → 803 MB | 10 → 10 | 381 → 204 |
| `alfresco-content-repository-community` | 181 → 156 | 839 → 752 MB | 10 → 10 | 381 → 204 |
| `alfresco-transform-core-aio` | 577 → 553 | 2095 → 2066 MB | 12 → 12 | 712 → 547 |
| `alfresco-imagemagick` | 405 → 380 | 1294 → 1225 MB | 12 → 12 | 673 → 504 |
| `alfresco-libreoffice` | 347 → 324 | 1604 → 1559 MB | 11 → 11 | 441 → 275 |
| `alfresco-tika` | 235 → 210 | 839 → 760 MB | 10 → 10 | 384 → 207 |
| `alfresco-transform-misc` | 173 → 149 | 755 → 673 MB | 10 → 10 | 378 → 201 |
| `alfresco-pdf-renderer` | 173 → 150 | 688 → 617 MB | 10 → 10 | 378 → 208 |

Counts are unique CVE IDs. Grype match counts are three to four times higher,
since one CVE is reported once per affected rpm.

**Gated count is unchanged** because `java/Dockerfile` runs `$PKG_MGR upgrade -y`
before installing anything, so both builds start fully patched and the base tag's
backlog of fixable CVEs is irrelevant. What remains has no fixed rpm published:
for the repository image, nine openssl CVEs (`CVE-2026-14456` High, three
Medium, five Low) plus `CVE-2026-4878` in `libcap`; the transform engines add
`CVE-2025-10911` in `libxslt` and `CVE-2026-5201` in `gdk-pixbuf2`. None are
removable by base image variant.

**Two CVEs were introduced**, identically on every image: `CVE-2025-5372` and
`CVE-2026-3731`, both Medium and both unfixed, in `libssh`. The minimal base
ships full `curl` rather than `curl-minimal`, and full `libcurl` requires
`libssh` for its SFTP/SCP backends. Nothing else was added — the other 67 new
Grype matches are the same CVEs re-reported under renamed rpms (`curl`/`libcurl`
for `curl-minimal`/`libcurl-minimal`, and `python-unversioned-command` for
`python3`). 33 packages were dropped, mostly the `dnf`/`yum` stack;
`vim-minimal`, `binutils` and `binutils-gold` account for most of the reduction.

## Confirmed in CI

The weekly workflow reran on `86d215f7` (2026-09-17) and closed 24 code scanning
alerts, 107 open to 83, with nothing new. All 24 were on
`ats/alfresco-shared-file-store` and `ats/alfresco-transform-router`, which are
also `FROM java_base`; `repository` and `tengines` did not move, as the local
comparison predicted. Sixteen of the closures are `vim-minimal`, a package
`:9-minimal` does not ship. The other eight (`expat`, `glib2`,
`coreutils-single`) closed because changing the base tag invalidated a stale
`java_base` `upgrade -y` layer, not because of the minimal base itself — those
packages are still present, at patched versions.

## Caveats

- Measured on `linux/arm64`, where the `tengine` Dockerfiles install LibreOffice
  from the `devel` repo instead of the bundled rpms, so transform engine package
  counts differ from the `linux/amd64` CI scans. The comparison itself holds:
  both sides were built the same way.
- The `before` side is the current tree with the base tag overridden, not the
  pre-OPSEXP-4315 tree, so `tar` and `dejavu-sans-fonts` are present on both.
- Counts move with the vulnerability database. Only the rpm and size columns are
  meaningful against a scan taken with a different DB snapshot; verify current
  numbers against [code
  scanning](https://github.com/Alfresco/alfresco-dockerfiles-bakery/security/code-scanning)
  instead.
