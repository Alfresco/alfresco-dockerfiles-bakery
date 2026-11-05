# Bring your own repository

By default this project fetches Alfresco artifacts from the Alfresco Nexus
server. Every artifact in an `artifacts-*.yaml` file declares a `source`, and
each source is defined in [`sources.yaml`](../sources.yaml) at the root of the
repository. A source is simply the root URL of a Maven repository. This means
you can mirror the Alfresco artifacts into your own Maven repository (Nexus,
Artifactory, a plain HTTP server following the Maven layout, ...) and point the
build at it without editing any Dockerfile or manifest.

## How sources work

`sources.yaml` maps a source name to the root URL of a Maven repository:

```yaml
sources:
  public:
    url: https://nexus.alfresco.com/nexus/repository/public
  releases:
    url: https://nexus.alfresco.com/nexus/repository/releases
  enterprise-releases:
    url: https://nexus.alfresco.com/nexus/repository/enterprise-releases
  activiti-enterprise-releases:
    url: https://nexus.alfresco.com/nexus/repository/activiti-enterprise-releases
  thirdparty:
    url: https://nexus.alfresco.com/nexus/repository/thirdparty
```

An artifact declaring `source: releases` with group `org.alfresco`, name
`alfresco-aos-module` and version `3.4.3` is fetched from:

```text
<releases url>/org/alfresco/aos-module/alfresco-aos-module/3.4.3/alfresco-aos-module-3.4.3.amp
```

that is, the source URL followed by the standard Maven
`group/artifact/version/file` path.

No credentials are stored in `sources.yaml`. `fetch_artifacts.py` resolves them by
the host of each source URL: the `NEXUS_USERNAME` / `NEXUS_PASSWORD` override for
the Nexus host, otherwise your `~/.netrc` file. Sources whose host has no matching
entry are accessed anonymously. In CI the `~/.netrc` is built from per-source
secrets (see [CI authentication for a new
source](#ci-authentication-for-a-new-source)).

## Using your own repositories

1. Mirror the Alfresco artifacts you need into your own Maven repository (or
   repositories), preserving their group/artifact/version coordinates.

2. Edit `sources.yaml` so each source URL points at your repository. You can keep
   the five source names and repoint them, or host everything under a single
   root:

   ```yaml
   sources:
     public:
       url: https://maven.example.com/repository/alfresco-public
     releases:
       url: https://maven.example.com/repository/alfresco-releases
     enterprise-releases:
       url: https://maven.example.com/repository/alfresco-enterprise
     activiti-enterprise-releases:
       url: https://maven.example.com/repository/alfresco-activiti
     thirdparty:
       url: https://maven.example.com/repository/thirdparty
   ```

   To keep the committed `sources.yaml` untouched, write your own file and point
   the fetch script at it with the `SOURCES_FILE` environment variable:

   ```sh
   export SOURCES_FILE=/path/to/my-sources.yaml
   ```

3. Add a `~/.netrc` entry for every host your sources use:

   ```sh
   machine maven.example.com
     login myuser
     password mypassword
   ```

   ```sh
   chmod 600 ~/.netrc
   ```

   Omit the entry for hosts that serve the artifacts anonymously.

4. Build as usual (for example `make enterprise`) or run the fetch script
   directly:

   ```sh
   python3 scripts/fetch_artifacts.py repository --log-level DEBUG
   ```

## CI authentication for a new source

The build, test, and scan workflows write the Nexus `~/.netrc` entry inline, then
run `scripts/write_source_netrc.py` to add a `~/.netrc` entry for every other
source whose credentials are supplied as secrets. `fetch_artifacts.py` then reads
those credentials from `~/.netrc` by host, exactly as it reads a developer's own
`~/.netrc`. Environment variables are only how the secrets reach that script; the
fetch itself never reads credentials from the environment.

For a source named `<name>`, the two secrets are
`<NAME>_ARTIFACTS_USERNAME` / `<NAME>_ARTIFACTS_PASSWORD`, plus a trusted host
variable `<NAME>_ARTIFACTS_HOST`, where `<NAME>` is the
source name upper-cased, with every run of non-alphanumeric characters replaced by
a single underscore and any leading or trailing underscore removed. The prefix
must contain a letter, must not start with a digit, and must be unique across
sources; the script fails fast otherwise. Source names must also be text: quote
names that YAML would read as another type, such as `"true"`, `"null"` or `"123"`.
For example a source named `my-mirror` uses `MY_MIRROR_ARTIFACTS_USERNAME` /
`MY_MIRROR_ARTIFACTS_PASSWORD` / `MY_MIRROR_ARTIFACTS_HOST`.

Examples of how a source name maps to its secret names:

| Source name            | Prefix                | Variables                                                       | Valid |
| ---------------------- | --------------------- | -------------------------------------------------------------- | ----- |
| `my-mirror`            | `MY_MIRROR`           | `MY_MIRROR_ARTIFACTS_USERNAME` / `..._PASSWORD`                 | yes   |
| `enterprise-releases`  | `ENTERPRISE_RELEASES` | `ENTERPRISE_RELEASES_ARTIFACTS_USERNAME` / `..._PASSWORD`       | yes   |
| `acme.repo`            | `ACME_REPO`           | `ACME_REPO_ARTIFACTS_USERNAME` / `..._PASSWORD`                 | yes   |
| `2mirror`              | `2MIRROR`             | — (prefix starts with a digit)                                  | no    |
| `true` (unquoted)      | —                     | — (YAML reads it as a boolean, not text; quote it)              | no    |
| `---`                  | `` (empty)            | — (no alphanumeric characters)                                 | no    |
| `my-mirror` + `my.mirror` | `MY_MIRROR`        | — (two sources collide on one prefix)                          | no    |

### Worked example: add an authenticated `my-mirror` source

1. Declare the source in `sources.yaml` (URL only — no credentials live here):

   ```yaml
   sources:
     my-mirror:
       url: https://maven.acme.example.com/repository/alfresco
   ```

2. Point an artifact at it via its `source` field in an `artifacts-*.yaml` file:

   ```yaml
   artifacts:
     my-thing:
       name: my-thing
       version: 1.0.0
       classifier: .jar
       group: com.acme
       source: my-mirror
       path: ./repository/libs
   ```

3. Add the two credentials as repository secrets named
   `MY_MIRROR_ARTIFACTS_USERNAME` and `MY_MIRROR_ARTIFACTS_PASSWORD`, and add a
   repository **variable** `MY_MIRROR_ARTIFACTS_HOST` set to the source's expected
   host (e.g. `maven.acme.example.com`). The host is a variable, not a secret,
   because it is not sensitive — it exists so the script can refuse to write the
   credentials if a pull request repoints the source's `url` at another host.

4. Pass those secrets and the host variable to the `Setup additional source
   authentication` step (the one that runs `scripts/write_source_netrc.py`) via its
   `env:` block. The three workflows carry a commented placeholder for exactly
   this — uncomment and fill it in:

   ```yaml
   - name: Setup additional source authentication
     shell: bash
     env:
       MY_MIRROR_ARTIFACTS_USERNAME: ${{ secrets.MY_MIRROR_ARTIFACTS_USERNAME }}
       MY_MIRROR_ARTIFACTS_PASSWORD: ${{ secrets.MY_MIRROR_ARTIFACTS_PASSWORD }}
       MY_MIRROR_ARTIFACTS_HOST: ${{ vars.MY_MIRROR_ARTIFACTS_HOST }}
     run: python3 ./scripts/write_source_netrc.py
   ```

   `write_source_netrc.py` writes the credentials only when the host in
   `sources.yaml` matches `MY_MIRROR_ARTIFACTS_HOST`; a mismatch (for example a
   pull request that changed the `url`) fails the step without writing anything.

Nothing needs changing until such a source exists: every source shipped in
`sources.yaml` is on the Nexus host and authenticates through the inline Nexus
entry, so the workflows pass no per-source secrets today.

### Running locally

Locally, add a `~/.netrc` entry for each host your sources use — the same file
`fetch_artifacts.py` reads in CI:

```sh
machine maven.acme.example.com
  login alice
  password s3cret
```

```sh
chmod 600 ~/.netrc
```

Then build as usual, or run the fetch directly:

```sh
python3 scripts/fetch_artifacts.py repository --log-level DEBUG
```

Omit the entry for hosts that serve artifacts anonymously. `fetch_artifacts.py`
resolves credentials by host: the `NEXUS_USERNAME` / `NEXUS_PASSWORD` override for
the Nexus host, then `~/.netrc`, then anonymous access. It never reads per-source
credentials from the environment, and credential values are never logged.

## Behaviour and troubleshooting

- **Authentication failures are skipped, not fatal.** When a source returns
  `401` or `403` the artifact is skipped and listed in an end-of-run summary, so
  a run that can only reach some sources still makes progress. A wrong URL
  (anything else, such as `404`) fails the run loudly.
- **The download cache is isolated per source** under
  `artifacts_cache/<source>/`, so two sources serving a file with the same name
  never collide.
- **Validation is strict.** Every artifact must declare a `source` that exists in
  the active sources file. A missing source, an unknown source, or a leftover
  `repository` key fails fast with a clear error.
- **Credentials never cross hosts.** `fetch_artifacts.py` sends each request only
  the `~/.netrc` credentials for that request's host. When CI builds `~/.netrc`
  from per-source secrets, `write_source_netrc.py` writes a source's secret only if
  its `sources.yaml` host matches the trusted `<NAME>_ARTIFACTS_HOST` repository
  variable, so a pull request that repoints a source's `url` cannot redirect the
  credentials to another host.
- **Version bumps only authenticate to Nexus.** The updatecli bump workflow
  (`.github/updatecli.tpl`) embeds the `NEXUS_USERNAME`/`NEXUS_PASSWORD` pair only
  for sources on a trusted Nexus host; sources on any other host are queried
  anonymously, so pointing a source at a third-party repository never sends
  Alfresco credentials to it. To bump versions from an authenticated third-party
  repository, add its host to the trusted list in the template and provide its
  credentials to the workflow.

## Limitations

- **One credential per host.** `~/.netrc` is keyed by host, so two sources on the
  same host cannot use different credentials. In CI the netrc builder writes the
  first such source's entry and skips the rest of that host; the others then reuse
  that credential and fail with `401`/`403` if it is wrong. Give colliding sources
  distinct hosts if they need distinct credentials.
- **CI auth for a new source is a manual, two-step change.** GitHub Actions cannot
  enumerate secrets, so each new authenticated source needs its two secrets
  created and referenced explicitly in the workflow step's `env:`. There is no
  automatic discovery; nothing happens until both are done.
- **The CI netrc builder requires Python 3.11+.** `scripts/write_source_netrc.py`
  quotes credentials so values with spaces or special characters round-trip, and
  only Python 3.11+'s `netrc` parser understands those quotes. This is satisfied
  by the CI runners; it does not affect developers, who maintain their own
  `~/.netrc`.
