# Alfresco Dockerfiles Bakery 🍞

[![CI](https://github.com/Alfresco/alfresco-dockerfiles-bakery/actions/workflows/build_and_test.yml/badge.svg)](https://github.com/Alfresco/alfresco-dockerfiles-bakery/actions/workflows/build_and_test.yml)
[![CI from forks](https://github.com/Alfresco/alfresco-dockerfiles-bakery/actions/workflows/build_forks.yml/badge.svg)](https://github.com/Alfresco/alfresco-dockerfiles-bakery/actions/workflows/build_forks.yml)

This projects aims at providing a quick and easy way to build and maintain
Alfresco Docker images based on the official Alfresco artifacts with the help of
[Docker Bake](https://docs.docker.com/build/bake/).

- [Alfresco Dockerfiles Bakery 🍞](#alfresco-dockerfiles-bakery-)
  - [Prerequisites](#prerequisites)
    - [Nexus authentication](#nexus-authentication)
  - [Getting started quickly](#getting-started-quickly)
  - [Customizing the images](#customizing-the-images)
    - [Customizing the Alfresco Content Repository image](#customizing-the-alfresco-content-repository-image)
  - [Supported Architectures](#supported-architectures)
    - [Targeting a specific architecture](#targeting-a-specific-architecture)
    - [Multi-arch images](#multi-arch-images)
  - [Testing locally](#testing-locally)
  - [Security scanning](#security-scanning)

## Prerequisites

Building images requires the following tools:

- A recent enough Docker installation (with buildx support)
- Credentials to access the Alfresco artifacts (Nexus server), if building
  Enterprise images
- Some common unix tools: `jq`, `wget`, `make`

### Nexus authentication

Configuring the authentication to Alfresco Nexus server must be done using one
of the standard `wget` configuration files, like `~/.netrc`.

Using your preferred editor, create `~/.netrc` with the following contents:

```sh
machine nexus.alfresco.com
login myuser
password mypassword
```

Make sure to make the file non-world readable:

```sh
chmod 600 ~/.netrc
```

## Getting started quickly

If you do not plan on applying specific customizations but just want to get
Alfresco images updated (e.g. with the latest OS security patches), you can
simply run the command below from the root of this project:

```sh
make all
```

This command will build locally all the docker images this project offers.

For more information on the available images, browse the top level folders,
excluding `artifacts_cache`, `scripts` and `test`.

For more information on the available targets, run:

```sh
make help
```

Below are some environment variables which can be used to customize the build
process:

- `REGISTRY`: The registry where the images will be pushed (authentication is
  ensured by the `make` wrapper)
- `REGISTRY_NAMESPACE`: The namespace where the images will be pushed (e.g.
  REGISTRY/REGISTRY_NAMESPACE/IMAGE_NAME:TAG)
- `TAG`: The tag to use for the images (default is `latest`)
- `TARGETARCH`: The architecture to build the images for (default is the
  architecture of the system where the build is run). See [Supported
  Architectures](#supported-architectures) for more information.
- `BAKE_NO_CACHE`: Set to `1` to disable the cache during the build process
- `BAKE_NO_PROVENANCE`: Set to `1` to not add provenance metadata during the build
  process. This is mostly useful if your registry do not support it.

For example, to build multi-arch images for ARM64 and X86_64 and push them to a
custom registry, you can run the following command:

```sh
export REGISTRY=myecr.domain.tld REGISTRY_NAMESPACE=myalfrescobuilds TARGETARCH=linux/amd64,linux/arm64
make all
```

## Customizing the images

### Customizing the Alfresco Content Repository image

The Alfresco Content Repository image can be customized by adding different
types of files in the right locations:

- Alfresco Module Packages (AMPs) files in the [amps](repository/amps/README.md)
  folder
  - Enterprise-only AMPs files in the [amps-enterprise](repository/amps_enterprise/README.md)
    folder
  - Community-only AMPs files in the [amps-community](repository/amps_community/README.md)
    folder
- Additional JAR files for the JRE in the [libs](repository/libs/README.md) folder

## Supported Architectures

Depending on the environment where you plan to run the docker images you build,
it is possible to build Alfresco images the following architectures:

- X86_64 (linux/amd64): Regular intel processor based systems
- ARM64 (linux/arm64): ARM processor based systems (e.g. Apple Silicon or AWS
  Graviton)

By default, the images are built for the architecture of the system where the
build is run.

### Targeting a specific architecture

To build images for a specific architecture, you can set the `TARGETARCH`
environment variable to the desired architecture.
For example, to build all Alfresco images for ARM64, you can run the following
command:

```sh
export TARGETARCH=linux/arm64
make all
```

To build just a specific image use you'll need to use `docker buildx bake`
directly, but the `TARGETARCH` environment variable also works:

```sh
export TARGETARCH=linux/arm64
docker buildx bake tengine_imagemagick
```

### Multi-arch images

Images can be built with multi-arch support. This is done by using the
same environment variable as above, and passing target architectures as a
comma-separated list.
By doing so, you're not solely build an image and its manifest, but a list of
manifests for each target architecture. That makes it possible to reference the
same image name and tag, and have the right image pulled for the right
architecture.

```sh
export TARGETARCH=linux/amd64,linux/arm64
make all
```

It's important to note that building multi-arch images requires the use of
Docker BuildKit, which is enabled by default in Docker 20.10 and later and
also requires images to be pushed to a registry that supports multi-arch.

:warning: Multi-arch build cannot be loaded into the local docker image cache.
This is due to a limitation of the `docker` exporter in BuildKit.
In order to produce multi-arch images one needs to:

- Set the REGISTRY environment variable to the target registry
- Set the REGISTRY_NAMESPACE environment variable to the target namespace

The `make` wrapper would handle the authentication part for you:

```sh
export REGISTRY=myecr.domain.tld REGISTRY_NAMESPACE=myalfrescobuilds TARGETARCH=linux/amd64,linux/arm64
make repo
```

You can also run bake directly but you need to be sure to have done the
authentication before running the `docker buildx bake` command with an
additional argument to tell the tool to push the images to the registry:

```sh
export REGISTRY=myecr.domain.tld REGISTRY_NAMESPACE=myalfrescobuilds TARGETARCH=linux/amd64,linux/arm64
docker buildx bake repo --set *.output=type=registry,push=true
```

## Testing locally

You can easily load all the built image in a local kind cluster with:

```sh
kind load docker-image $(docker images --format "{{.Repository}}" | grep "^localhost/alfresco" | xargs)
```

Then you can run an helm install passing as values the provided
[test-overrides.yaml](./test/helm/test-overrides.yaml).

## Security scanning

The images built by this project are automatically scanned for vulnerabilities
using Grype, if the `grype` binary is available in the PATH.

If you want to run the security scan manually, you can use the following command:

```sh
make grype GRYPE_TARGET=repo GRYPE_OPTS="-f high --only-fixed --ignore-states wont-fix"
```

You can pass `GRYPE_OPTS` to override the default options passed to Grype, which
by default exit with a non-zero status if any vulnerability greater than high is
found and is filtering out known issues for which a fix is not available (yet or
ever).
