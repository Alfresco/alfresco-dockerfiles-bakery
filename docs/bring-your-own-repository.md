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

No credentials are stored in `sources.yaml`. They are resolved per source, from
the `<NAME>_ARTIFACTS_USERNAME` / `<NAME>_ARTIFACTS_PASSWORD` environment
variables (see [CI authentication for a new source](#ci-authentication-for-a-new-source)),
then, for the Nexus host only, from `NEXUS_USERNAME` / `NEXUS_PASSWORD`, and
otherwise from your `~/.netrc` file, keyed by the host of each source URL.
Sources with no matching credentials are accessed anonymously.

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

The build, test, and scan workflows write the Nexus `~/.netrc` entry inline.
Every other source authenticates through environment variables that
`fetch_artifacts.py` reads directly: for a source named `<name>` it looks up
`<NAME>_ARTIFACTS_USERNAME` / `<NAME>_ARTIFACTS_PASSWORD`, where `<NAME>` is the
source name upper-cased, with every run of non-alphanumeric characters replaced by
a single underscore and any leading or trailing underscore removed. The prefix
must contain a letter, must not start with a digit, and must be unique across
sources; `fetch_artifacts.py` fails fast otherwise. For example a source named
`my-mirror` resolves to `MY_MIRROR_ARTIFACTS_USERNAME` / `MY_MIRROR_ARTIFACTS_PASSWORD`.

Examples of how a source name maps to its credential variables:

| Source name            | Prefix                | Variables                                                       | Valid |
| ---------------------- | --------------------- | -------------------------------------------------------------- | ----- |
| `my-mirror`            | `MY_MIRROR`           | `MY_MIRROR_ARTIFACTS_USERNAME` / `..._PASSWORD`                 | yes   |
| `enterprise-releases`  | `ENTERPRISE_RELEASES` | `ENTERPRISE_RELEASES_ARTIFACTS_USERNAME` / `..._PASSWORD`       | yes   |
| `acme.repo`            | `ACME_REPO`           | `ACME_REPO_ARTIFACTS_USERNAME` / `..._PASSWORD`                 | yes   |
| `2mirror`              | `2MIRROR`             | — (prefix starts with a digit)                                  | no    |
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
   `MY_MIRROR_ARTIFACTS_USERNAME` and `MY_MIRROR_ARTIFACTS_PASSWORD`.

4. Pass only those secrets to the step that fetches artifacts, via its `env:`
   block. In `.github/workflows/reusable_bake_build.yml` that is the step that
   runs `fetch_artifacts.py` (currently named `Fetch artifacts with test from
   nexus for ACS`; despite the name it downloads from every source, not only
   Nexus):

   ```yaml
   - name: Fetch artifacts for ACS
     shell: bash
     env:
       ACS_VERSION: ${{ inputs.version }}
       MY_MIRROR_ARTIFACTS_USERNAME: ${{ secrets.MY_MIRROR_ARTIFACTS_USERNAME }}
       MY_MIRROR_ARTIFACTS_PASSWORD: ${{ secrets.MY_MIRROR_ARTIFACTS_PASSWORD }}
     run: |
       python3 ./scripts/fetch_artifacts.py '${{ inputs.artifacts-to-fetch }}'
   ```

   In `.github/workflows/grype-scan.yml` and `.github/workflows/test-make.yml`
   the fetch runs inside `make`, so add the same `env:` to the `make` step:

   ```yaml
   - env:
       MY_MIRROR_ARTIFACTS_USERNAME: ${{ secrets.MY_MIRROR_ARTIFACTS_USERNAME }}
       MY_MIRROR_ARTIFACTS_PASSWORD: ${{ secrets.MY_MIRROR_ARTIFACTS_PASSWORD }}
     run: make ${{ matrix.target }}
   ```

Nothing needs changing until such a source exists: every source shipped in
`sources.yaml` is on the Nexus host and authenticates through the inline Nexus
entry, so the workflows carry no per-source `env:` today.

### Running locally

Locally you can either export the same variables:

```sh
export MY_MIRROR_ARTIFACTS_USERNAME='alice'
export MY_MIRROR_ARTIFACTS_PASSWORD='s3cret'
python3 scripts/fetch_artifacts.py repository
```

or add a `~/.netrc` entry for the source's host (keyed by host, not source name):

```sh
machine maven.acme.example.com
  login alice
  password s3cret
```

When both variables are set the source authenticates with them. Setting only one
is treated as a misconfiguration and `fetch_artifacts.py` fails fast. When
neither is set the source falls back to `NEXUS_USERNAME` / `NEXUS_PASSWORD`
(Nexus host only), then `~/.netrc`, and finally anonymous access. Only the named
secrets a source needs are exposed to the process, and credential values are
never logged.

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
- **Credentials never cross hosts.** Each request carries only the credentials of
  its own source's host. Credentials supplied through
  `<NAME>_ARTIFACTS_*` are tied to the source *name*, not its host, so review any
  change to a source's `url` in `sources.yaml` as carefully as a change to the
  secret itself.
- **Version bumps only authenticate to Nexus.** The updatecli bump workflow
  (`.github/updatecli.tpl`) embeds the `NEXUS_USERNAME`/`NEXUS_PASSWORD` pair only
  for sources on a trusted Nexus host; sources on any other host are queried
  anonymously, so pointing a source at a third-party repository never sends
  Alfresco credentials to it. To bump versions from an authenticated third-party
  repository, add its host to the trusted list in the template and provide its
  credentials to the workflow.
