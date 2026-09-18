# Security scanning baseline

The default base image moved from `docker.io/rockylinux/rockylinux:9` to
`:9-minimal` (OPSEXP-4315), which dropped 33 packages from every image built
from `java_base`. On the repository image that took unique Grype CVEs from 381
to 204 and size from 890 to 803 MB, and the weekly workflow closed 24 code
scanning alerts, 107 open down to 83.

Resolved, all from removing `vim-minimal`:

- `CVE-2026-73072`, `CVE-2026-73076`, `CVE-2026-73077`, `CVE-2026-73078` (high)
- `CVE-2026-28420`, `CVE-2026-52859`, `CVE-2026-55892`, `CVE-2026-59857` (medium)

Introduced, neither reachable as shipped, since the minimal base ships full
`curl` and full `libcurl` links `libssh`:

- `CVE-2025-5372` (medium), only present in a libssh built against OpenSSL
  below 3.0, and this one links `libcrypto.so.3`
- `CVE-2026-3731` (medium), needs an `sftp://` transfer against a hostile peer,
  and the images have no ssh client

Unchanged is the gated count, the `--only-fixed --ignore-states wont-fix` set
the workflow uploads, because `java/Dockerfile` upgrades all packages before
anything else, so both bases start fully patched. What remains has no fixed rpm
yet: openssl and `libcap` everywhere, `libxslt` and `gdk-pixbuf2` on the
transform engines.
