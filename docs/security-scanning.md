# Security scanning baseline

A reference point for Grype results, so the next base image change has something
to compare against. Taken when the default base moved from
`docker.io/rockylinux/rockylinux:9` to `:9-minimal` (OPSEXP-4315).

Measured on 2026-09-17 with Grype v0.118.0 and DB v6.1.9, `ACS_VERSION=26`, on
`linux/arm64`. Both sides came from `f3b113f` with only `IMAGE_BASE_LOCATION`
varied and `GRYPE_DB_AUTO_UPDATE=false`, so the base tag is the one variable.
The scan needs the same `TAG` and `IMAGE_BASE_LOCATION` as the build, because
`make grype` re-resolves tags through `docker buildx bake --print`.

```sh
TAG=before IMAGE_BASE_LOCATION=docker.io/rockylinux/rockylinux:9 make repository tengines
TAG=after make repository tengines
TAG=<side> make grype GRYPE_TARGET=<target> GRYPE_OUTPUT_DIR=scan/<side> \
  GRYPE_OUTPUT_FORMAT=json GRYPE_OPTS="--only-fixed --ignore-states wont-fix"
```

## Result

Unique CVEs roughly halved and images lost about a tenth of their size. The
gated count stayed where it was. Gated here means
`--only-fixed --ignore-states wont-fix`, the filter the weekly workflow uploads
from.

| Image | rpms | Size | Gated CVEs | Total CVEs |
| --- | --- | --- | --- | --- |
| `alfresco-content-repository` (both editions) | 181 → 156 | 890 → 803 MB | 10 → 10 | 381 → 204 |
| `alfresco-transform-core-aio` | 577 → 553 | 2095 → 2066 MB | 12 → 12 | 712 → 547 |
| `alfresco-imagemagick` | 405 → 380 | 1294 → 1225 MB | 12 → 12 | 673 → 504 |
| `alfresco-libreoffice` | 347 → 324 | 1604 → 1559 MB | 11 → 11 | 441 → 275 |
| `alfresco-tika` | 235 → 210 | 839 → 760 MB | 10 → 10 | 384 → 207 |
| `alfresco-transform-misc` | 173 → 149 | 755 → 673 MB | 10 → 10 | 378 → 201 |
| `alfresco-pdf-renderer` | 173 → 150 | 688 → 617 MB | 10 → 10 | 378 → 208 |

Counts are unique CVE IDs. Grype match counts run three to four times higher,
because a CVE is reported once per affected rpm.

The gated count cannot move, because `java/Dockerfile` runs `$PKG_MGR upgrade -y`
before anything else, so both builds start fully patched. What survives has no
fixed rpm published yet: openssl and `libcap` everywhere, `libxslt` and
`gdk-pixbuf2` on the transform engines. None of those packages go away with a
base image variant.

Two CVEs came in on every image, `CVE-2025-5372` and `CVE-2026-3731` in
`libssh`, both medium and unfixed. The minimal base ships full `curl` rather
than `curl-minimal`, and full `libcurl` pulls `libssh` in for SFTP. The other 67
new matches are existing CVEs reported again under renamed rpms, `curl` and
`libcurl` for `curl-minimal` and `libcurl-minimal`, `python-unversioned-command`
for `python3`. Going the other way, 33 packages left, mostly the `dnf` and `yum`
stack, with `vim-minimal` and `binutils` accounting for most of the drop.

## What the workflow saw

The run on `86d215f7` (2026-09-17) closed 24 alerts, 107 down to 83, and opened
none. `repository` and `tengines` held steady as predicted. All 24 closures were
on `ats/alfresco-shared-file-store` and `ats/alfresco-transform-router`.

Sixteen were `vim-minimal` and will not return, because `:9-minimal` has no such
package. The other eight (`expat`, `glib2`, `coreutils-single`) are still in the
images at patched versions, so they closed because this build resolved newer
rpms, not because of the base image.

## Caveats

- Measured on `linux/arm64`, where the `tengine` Dockerfiles take LibreOffice
  from the `devel` repo instead of the bundled rpms, so transform engine package
  counts will not match the `linux/amd64` CI scans.
- The before side is the current tree with the base tag overridden, not the
  pre-OPSEXP-4315 tree, so `tar` and `dejavu-sans-fonts` sit on both sides.
- Counts move with the vulnerability database, so only the rpm and size columns
  mean anything against a scan on a different DB snapshot. For current numbers
  use [code
  scanning](https://github.com/Alfresco/alfresco-dockerfiles-bakery/security/code-scanning).
