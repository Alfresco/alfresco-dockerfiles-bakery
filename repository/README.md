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
