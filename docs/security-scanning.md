# Security scanning baseline

Grype results before and after the default base image moved from
`docker.io/rockylinux/rockylinux:9` to `:9-minimal` (OPSEXP-4315). Measured on
2026-09-17 with Grype v0.118.0 against one database snapshot, on `linux/arm64`,
building `repository` and `tengines` from `f3b113f` with only
`IMAGE_BASE_LOCATION` varied.

| Image | rpms | Size | Gated CVEs | Total CVEs |
| --- | --- | --- | --- | --- |
| `alfresco-content-repository` (both editions) | 181 → 156 | 890 → 803 MB | 10 → 10 | 381 → 204 |
| `alfresco-transform-core-aio` | 577 → 553 | 2095 → 2066 MB | 12 → 12 | 712 → 547 |
| `alfresco-imagemagick` | 405 → 380 | 1294 → 1225 MB | 12 → 12 | 673 → 504 |
| `alfresco-libreoffice` | 347 → 324 | 1604 → 1559 MB | 11 → 11 | 441 → 275 |
| `alfresco-tika` | 235 → 210 | 839 → 760 MB | 10 → 10 | 384 → 207 |
| `alfresco-transform-misc` | 173 → 149 | 755 → 673 MB | 10 → 10 | 378 → 201 |
| `alfresco-pdf-renderer` | 173 → 150 | 688 → 617 MB | 10 → 10 | 378 → 208 |

Counts are unique CVE IDs. Gated means `--only-fixed --ignore-states wont-fix`,
the filter the weekly workflow uses.

Total CVEs fell by 23% on `transform-core-aio` up to 47% on `transform-misc`,
almost all of it from dropping `vim-minimal` and `binutils`. The gated count
stayed where it was. `java/Dockerfile` runs
`$PKG_MGR upgrade -y` before anything else, so both builds start fully patched
and what survives has no fixed rpm published yet: openssl and `libcap`
everywhere, `libxslt` and `gdk-pixbuf2` on the transform engines.

Two CVEs came in on every image, `CVE-2025-5372` and `CVE-2026-3731` in
`libssh`, both medium and unfixed. The minimal base ships full `curl`, and full
`libcurl` needs `libssh` for SFTP.

The weekly workflow has since run on this base and closed 24 alerts, 107 open
down to 83, opening none. All were on the two `ats` images. Sixteen were
`vim-minimal`, which `:9-minimal` does not ship, and the other eight closed
because that build resolved newer rpms rather than because of the base image.

Numbers move with the vulnerability database, so for current figures use [code
scanning](https://github.com/Alfresco/alfresco-dockerfiles-bakery/security/code-scanning).
