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

No credentials are stored in `sources.yaml`. They are resolved per source, by the
host of each source URL, from your `~/.netrc` file. Sources whose host has no
matching entry are accessed anonymously.

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
  its own source's host.
