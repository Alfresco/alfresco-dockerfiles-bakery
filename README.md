# Alfresco Docker images builder

This projects aims at providing a quick and easy to build and maintain Alfresco
Docker images.

## Getting started quickly

If you do not plan on applying specific customizations but just want to get
Alfresco images updated (e.g. with the latest OS security patches), you can
simply run the command below from the root of this project:

```bash
make all
```

This command will build locally all the docker images this project offers.
At the time of writing, these are:

* Alfresco Content Repository (Enterprise) 23.2.2
* Alfresco Search Enterprise 4.4.0
* Alfresco Transformation Services 4.1.3

The `make` wrapper provides other targets to build a subset of the images.
To get a list of all available targets, just type `make` and press TAB key
twice.

## Building the specific images

If you want to build a specific image, you can run one of the following make target:

* repo: build the Alfresco Content Repository image
* search_enterprise: build the Alfresco Search Enterprise images
* ats: build the Alfresco Transformation Service images

## Customizing the images

### Customizing the Alfresco Content Repository image

The Alfresco Content Repository image can be customized by adding different
types of files in the right locations:

* Alfresco Module Packages (AMPs) files in the [amps](repository/amps/README.md)
  folder
* Additional JAR files for the JRE in the [libs](repository/libs/README.md) folder

## Architecture choice

Depending on the environment where you plan to run the docker images you build,
it is possible to build Alfresco images the following architectures:

* X86_64 (linux/amd64): Regular intel processor based systems
* ARM64 (linux/arm64): ARM processor based systems (e.g. Apple Silicon or AWS
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

* Set the REGISTRY environment variable to the target registry
* Set the REGISTRY_NAMESPACE environment variable to the target namespace
* Ensure docker daemon is able to login to the target registry
* Enforce pushing resulting images to the target registry

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
