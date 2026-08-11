# Alfresco Content Repository image

## Description

This Docker file is used to build an Alfresco Content Repository image.

## Building the image

The Alfresco artifacts this image is built from are downloaded from Alfresco's
Nexus by `./scripts/fetch_artifacts.py` into the `repository/` sub folders.
From the root of this git repository:

```bash
make repository
```

## Customizing the image

Customizations belong in a git repository of your own. You need neither a clone
nor a fork of this one: this repository is consumed straight from git, so
upgrading never involves reconciling a merge. A minimal layout:

```tree
my-alfresco-images/
|_docker-bake.hcl
|_my-jdbc-drivers/
  |_postgresql-42.7.10.jar
```

The build inputs are read from named build contexts, each defaulting to the
folder it replaces in this repository:

| Context | Default | Holds |
| --- | --- | --- |
| `repo_distribution` | `repository/distribution` | ACS distribution zip |
| `repo_amps` | `repository/amps` | AMPs for both editions |
| `repo_amps_edition` | `repository/amps_<edition>` | Edition specific AMPs |
| `repo_libs` | `repository/libs` | JARs added to the Tomcat lib directory |
| `repo_simple_modules` | `repository/simple_modules` | Simple module JARs |

Your `docker-bake.hcl` holds your overrides only. Repoint the contexts you need
and set the tag your image should be published under:

```hcl
target "repository_enterprise" {
  contexts = {
    repo_libs = "cwd://my-jdbc-drivers"
  }
  tags = ["myregistry.domain.tld/alfresco-content-repository:26.2.1-acme1"]
}
```

Everything else, this repository's targets included, comes from the definition
you build against:

```bash
docker buildx bake \
  "https://github.com/Alfresco/alfresco-dockerfiles-bakery.git#v0.14.0" \
  -f cwd://docker-bake.hcl repository_enterprise
```

Upgrading to a newer Bakery release is a matter of changing that git ref, so
pin it to a release rather than to a branch.

Contexts are merged per key, so the ones you leave out keep their defaults. A
context you do override is *replaced*, not merged: your directory becomes the
entire content of that build input. Overriding `repo_libs` as above drops the
PostgreSQL JDBC driver this repository ships, and overriding `repo_amps` drops
`alfresco-share-services`, which Share needs. When you override a context, put
in it everything that build input is expected to hold, not only your own files.

`cwd://` is required for paths that are local to your own repository. Without
it, a relative path is resolved against the build context, which is the remote
git repository.

> **Deprecated**: copying your own files directly into the `repository/*`
> folders of a clone still works, but it requires a fork of this repository and
> leaves you reconciling conflicts on every upgrade. Prefer repointing the
> contexts above.

## Extending the image

Repointing a context covers what the image is built *from*. Anything else, such
as an OS package, an internal CA certificate or an extra configuration file, is
added by building an image of your own on top of the one this repository
produces, in the same bake invocation.

Reference the target you want to extend as a named context, from a target of
your own:

```hcl
target "repository_acme" {
  context = "cwd://custom/repository"
  contexts = {
    bakery = "target:repository_enterprise"
  }
  tags = ["myregistry.domain.tld/alfresco-content-repository:26.2.1-acme1"]
  labels = {
    "org.opencontainers.image.title" = "Acme Alfresco Content Repository"
    "org.opencontainers.image.vendor" = "Acme Corp"
    "org.opencontainers.image.source" = "https://github.com/acme/my-alfresco-images"
  }
}
```

Then write your own Dockerfile in `custom/repository`, starting from that
context:

```dockerfile
FROM bakery

USER root
RUN yum install -y acme-agent && yum clean all && rm -rf /var/cache/yum
COPY acme-ca.crt /etc/pki/ca-trust/source/anchors/
RUN update-ca-trust extract
USER alfresco
```

Build it by naming your own target:

```bash
docker buildx bake \
  "https://github.com/Alfresco/alfresco-dockerfiles-bakery.git#v0.14.0" \
  -f cwd://docker-bake.hcl repository_acme
```

Three things to keep in mind:

- The image runs as the unprivileged `alfresco` user. Switch to `root` for the
  steps that need it and switch back at the end, or your image starts as root.
- Labels are inherited from the base image, so without the `labels` block above
  your image reports Hyland as its vendor and this repository as its source.
  Override them so that your image describes itself.
- Files you add belong to `root` and miss the ownership pass applied while the
  base image is assembled. Give them the `alfresco` group when the repository
  has to read them.

Because this adds a layer on top of a finished image, it cannot change what the
image already contains: a file removed this way still ships in the layer
underneath, where image scanners will not report it.

## Running the image

### Alfresco repository configuration

All properties you would normally add in the alfresco-global.properties file can
be added in the `JAVA_OPTS` environment variable to the container.

For example, to set the database URL, you can use the following environment
variable:

```bash
docker run -e JAVA_OPTS="-Ddb.url=jdbc:postgresql://postgres.domain.tld:5432/alfresco" \
  alfresco-content-repository:mytag
```

> If the image is meant to be used with the Alfresco Content Services Helm
> chart, you can use other [higher level means of
> configuration](https://github.com/Alfresco/alfresco-helm-charts/blob/main/charts/alfresco-repository/docs/repository-properties.md).
