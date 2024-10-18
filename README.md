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
  - [Architecture choice](#architecture-choice)
    - [Targeting a specific architecture](#targeting-a-specific-architecture)
    - [Multi-arch images](#multi-arch-images)
    - [Testing locally](#testing-locally)

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

```bash
make all
```

This command will build locally all the docker images this project offers.

For more information on the available images, browse the top level folders,
excluding `artifacts_cache`, `scripts` and `test`.

For more information on the available targets, see [Makefile](./Makefile).

Below are some environment variables dedicated to the `make` wrapper which
can be used to customize the build process:

- BAKE_NO_CACHE: Set to `1` to disable the cache during the build process
- BAKE_NO_PROVENANCE: Set to `1` to not add provenance metadata during the build
  process. This is mostly useful if your registry do not support it.

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

## Architecture choice

Depending on the environment where you plan to run the docker images you build,
it is possible to build Alfresco images the following architectures:

- X86_64 (linux/amd64): Regular intel processor based systems
- ARM64 (linux/arm64): ARM processor based systems (e.g. Apple Silicon or AWS
  Graviton)

Other architectures are not suported.

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
Concretely, it means in order to produce multi-arch images one needs to:

- Set the REGISTRY environment variable to the target registry
- Set the REGISTRY_NAMESPACE environment variable to the target namespace
- Ensure docker daemon is able to login to the target registry
- Enforce pushing resulting images to the target registry

The `make` wrapper would handle the authentication part for you:

```sh
export REGISTRY=myecr.domain.tld REGISTRY_NAMESPACE=myorg TARGETARCH=linux/amd64,linux/arm64
make repo
```

> Enter username and password when/if prompted

If you're not using the `make wrapper` you need to first initiate the registry
authentication before running the `docker buildx bake` command with an
additional argument to tell the tool to push the images to the registry:

```sh
export REGISTRY=myecr.domain.tld REGISTRY_NAMESPACE=myorg TARGETARCH=linux/amd64,linux/arm64
docker login $REGISTRY
docker buildx bake repo --set *.output=type=registry,push=true
```

### Testing locally

You can easily load all the built image in a local kind cluster with:

```sh
kind load docker-image $(docker images --format "{{.Repository}}" | grep "^localhost/alfresco" | xargs)
```

Then you can run an helm install passing as values the provided
[test-overrides.yaml](./test/helm/test-overrides.yaml).
