# Alfresco Dockerfiles Bakery 🍞

[![release](https://img.shields.io/github/v/release/Alfresco/alfresco-dockerfiles-bakery?display_name=release)](https://github.com/Alfresco/alfresco-dockerfiles-bakery/releases/latest)
[![CI](https://github.com/Alfresco/alfresco-dockerfiles-bakery/actions/workflows/build_and_test.yml/badge.svg)](https://github.com/Alfresco/alfresco-dockerfiles-bakery/actions/workflows/build_and_test.yml)
[![CI from forks](https://github.com/Alfresco/alfresco-dockerfiles-bakery/actions/workflows/build_forks.yml/badge.svg)](https://github.com/Alfresco/alfresco-dockerfiles-bakery/actions/workflows/build_forks.yml)

As outlined in the [Hyland Alfresco support
policy](https://docs.alfresco.com/support/latest/policies/deployment/),
pre-built container images are intended as reference for creating your own
customized images, incorporating deployment guidelines, security best practices,
and any necessary custom extensions. While this policy remains unchanged, we are
supporting the community further by open-sourcing the Alfresco Dockerfiles
Bakery, a tool designed to simplify the deployment of the Alfresco platform and
assist you in building tailored container images, with the help of [Docker
Bake](https://docs.docker.com/build/bake/).

- [Alfresco Dockerfiles Bakery 🍞](#alfresco-dockerfiles-bakery-)
  - [Prerequisites](#prerequisites)
    - [Vagrant alternative](#vagrant-alternative)
    - [Nexus authentication](#nexus-authentication)
  - [Getting started quickly](#getting-started-quickly)
  - [Customizing the images](#customizing-the-images)
    - [Customizing the Alfresco Content Repository image](#customizing-the-alfresco-content-repository-image)
    - [Customizing the Share image](#customizing-the-share-image)
  - [Supported Architectures](#supported-architectures)
    - [Targeting a specific architecture](#targeting-a-specific-architecture)
    - [Multi-arch images](#multi-arch-images)
  - [Building older versions](#building-older-versions)
  - [Testing locally](#testing-locally)
    - [Testing with helm](#testing-with-helm)
    - [Testing with docker compose](#testing-with-docker-compose)
  - [Security scanning](#security-scanning)
  - [Fetch artifacts script](#fetch-artifacts-script)
  - [Known issues](#known-issues)
  - [Release](#release)

## Prerequisites

Building images requires the following tools:

- A recent enough Docker installation (with `buildx` support)
- Credentials to access the Alfresco artifacts (Nexus server), if building
  Enterprise images
- Some common unix tools: `jq`, `yq`, `make`
- Python 3 with pyyaml (`pip install pyyaml`) for fetching artifacts via the
  `fetch-artifacts.py` script

Alternatively, you can use the provided [Vagrantfile](Vagrantfile) to create a
dedicated VM with all the required tools installed. This is useful if you want
to build the images without installing the tools on your local machine.

### Vagrant alternative

Vagrant is the command line utility for managing the lifecycle of virtual machines.

To use the provided Vagrantfile, you need to have Vagrant and VirtualBox installed
on your machine. You can follow the instructions below to install them:

- Install [vagrant](https://developer.hashicorp.com/vagrant/install)
- Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

Then run from the main folder of this project:

```sh
vagrant up
```

Vagrant will create an ubuntu 24.04 virtual machine in VirtualBox, fetch all the
required Bakery dependencies, and then you can enter the environment by running:

```sh
vagrant ssh
```

Then you can proceed running the `make` commands as described later in this
document.

### Nexus authentication

Configuring the authentication to Alfresco Nexus server requires setting up
credentials in the standard `~/.netrc` authentication file.

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
make enterprise
```

or for Community edition:

```sh
make community
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

The Alfresco Content Repository image can be customized by adding files into
specific folders:

- Alfresco Module Packages (AMPs) files in the [amps](repository/amps/README.md)
  folder for both Enterprise and Community editions
  - For Enterprise-only AMPs files in the
    [amps-enterprise](repository/amps_enterprise/README.md) folder
  - For Community-only AMPs files in the
    [amps-community](repository/amps_community/README.md) folder
- Simple Module (JAR) files in the
  [simple_modules](repository/simple_modules/README.md) folder
- Additional JAR files for the JRE in the [libs](repository/libs/README.md)
  folder

### Customizing the Share image

The Share image can be customized by adding files into specific folders:

- Alfresco Module Packages (AMPs) files in the [amps](share/amps/README.md)
  folder
- Share Simple Module (JAR) files in the
  [simple_modules](share/simple_modules/README.md) folder

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

## Building older versions

Versions of artifacts being downloaded specific to the ACS version are defined
in `artifacts-XX.yaml` files for each component.

To build older version pass `ACS_VERSION` env to make command.
- ACS 23  - `ACS_VERSION=23` - Will use `artifacts-23.yaml` files
- ACS 7.4 - `ACS_VERSION=74` - Will use `artifacts-74.yaml` files
- ACS 7.3 - `ACS_VERSION=73` - Will use `artifacts-73.yaml` files

```sh
make enterprise ACS_VERSION=74
```

When using `make`, it sets the correct version of Tomcat based on the ACS version.
If you want to build older version of images using `docker buildx bake` it is
required to set the Tomcat versions manually in bake file or using env
variables.

```sh
export TOMCAT_VERSIONS_FILE=tomcat/tomcat_versions.yaml
export TOMCAT_MAJOR=$(yq e '.tomcat9.major' $TOMCAT_VERSIONS_FILE)
export TOMCAT_VERSION=$(yq e '.tomcat9.version' $TOMCAT_VERSIONS_FILE)
export TOMCAT_SHA512=$(yq e '.tomcat9.sha512' $TOMCAT_VERSIONS_FILE)
docker buildx bake tomcat_base
```

Before switching build to other version clean the artifacts using `make clean`
then fetch correct version with e.g.:

```sh
make clean prepare ACS_VERSION=74
```

Artifacts set in the artifacts file are fetched from the Nexus repository and
their checksum is verified, provided the artifact has a checksum value which is
a concatenation of the algorithm and optionally the checksum in the format
`<algorithm>:<checksum>`. If the checksum is not provided, the script will
try to fetch it from the Nexus repository reusing the computed artifact url and
appending the `.algorithm` extension to it.

## Testing locally

Once the images are built, you can test them locally using either Helm or Docker Compose.

### Testing with helm

Follow the general instructions for [installing Alfresco on
KinD](https://alfresco.github.io/acs-deployment/docs/helm/kind-deployment.html)
until the point where you have to run `helm install`.

If the images has not been pushed to a remote repository, you can easily load
all the locally built images in the local KinD cluster with:

```sh
kind load docker-image $(docker images --format "{{.Repository}}" | grep "^localhost/alfresco" | xargs)
```

Before running the `helm install` command, you need adjust the registry and
image namespace references in the provided
[test-overrides.yaml](test/helm/test-overrides.yaml) file:

```sh
REGISTRY=localhost REGISTRY_NAMESPACE=alfresco TAG=latest
sed -i "s|localhost/alfresco/|${REGISTRY}/${REGISTRY_NAMESPACE}/|g" test/helm/test-overrides.yaml
sed -i "s|tag: latest|tag: ${TAG}|g" test/helm/test-overrides.yaml
```

If you are testing the community edition, you also need to adjust the image
references for the Share and Repository images:

```sh
sed -i "s|/alfresco-content-repository|/alfresco-content-repository-community|g" test/helm/test-overrides.yaml
sed -i "s|/alfresco-share|/alfresco-share-community|g" test/helm/test-overrides.yaml
```

Then you can finally run `helm install` passing as values the provided files.

For enterprise edition:

```sh
helm install acs alfresco/alfresco-content-services \
  --values=test/helm/enterprise-integration-test-values.yaml \
  --values=test/helm/test-overrides.yaml \
  --values=test/helm/test-overrides-enterprise.yaml \
  --atomic \
  --timeout 10m0s \
  --namespace alfresco
```

For community edition:

```sh
helm install acs alfresco/alfresco-content-services \
  --values=test/helm/community_values.yaml \
  --values=test/helm/community-integration-test-values.yaml \
  --values=test/helm/test-overrides.yaml \
  --values=test/helm/test-overrides-community.yaml \
  --set global.search.sharedSecret=$(openssl rand -hex 24) \
  --atomic \
  --timeout 10m0s \
  --namespace=alfresco
```

### Testing with docker compose

You can use Docker Compose to test the built images locally as follows:

1. Fetch upstream compose definitions from acs-deployment repository:

   ```sh
   git clone https://github.com/Alfresco/acs-deployment.git
   ```

2. Copy the compose files from the acs-deployment repository to the test folder
   of this repository:

   ```sh
   cp -r acs-deployment/docker-compose/* test/
   ```

3. Run compose together with one of the available override files, which allow
   you to easily reference built images using
   `$REGISTRY/$REGISTRY_NAMESPACE/component-name:$TAG` format:

   ```sh
   export REGISTRY=localhost REGISTRY_NAMESPACE=alfresco TAG=latest
   docker compose -f test/compose.yaml -f test/enterprise-override.yaml up -d
   ```

   For community edition instead:

    ```sh
    export REGISTRY=localhost REGISTRY_NAMESPACE=alfresco TAG=latest
    docker compose -f test/community-compose.yaml -f test/community-override.yaml up -d
    ```

## Security scanning

The images built by this project may be scanned for vulnerabilities using Grype,
if the `grype` binary is available in the PATH.

> Grype is an open-source scanner for container images, ideal for identifying
> recent vulnerabilities, especially within base OS images. While it supports
> application libraries, it lacks reachability analysis, meaning it cannot
> confirm whether vulnerabilities are actually exploitable in the context of the
> application. For accurate insights, refer to Alfresco Security bulletins and
> contact Hyland support, as these sources provide vetted information after
> manual triaging of scanner findings within the application code. Remember to
> always assess findings within the context of your specific deployment.

If you want to run the security scan manually, you can use the following command:

```sh
make grype GRYPE_TARGET=repo GRYPE_OPTS="-f high --only-fixed --ignore-states wont-fix"
```

You can pass `GRYPE_OPTS` to override the default options passed to Grype, which
by default exit with a non-zero status if any vulnerability greater than high is
found and is filtering out known issues for which a fix is not available (yet or
ever).

You can also run grype automatically at the end of the build process by setting
`GRYPE_ONBUILD`:

```sh
make all GRYPE_ONBUILD=1
```

## Fetch artifacts script

A Python script to download artifacts from the Alfresco Nexus repository based
on YAML configuration files.

> We recommend using `make` for local operations on this repository but if you
> want to only leverage the fetching script here is the explanation

### Usage

```bash
python3 scripts/fetch_artifacts.py [targets...] [options]
```

### Arguments

#### Targets (optional)
You can specify one or more targets:

- **No arguments**: Processes the entire repository (only files matching
  `artifacts-*.yaml`)
- **Directory path**: Searches for artifact files in the specified directory
  (only files matching `artifacts-*.yaml` in that directory)
- **File path**: Processes a specific artifact YAML file
- **Glob pattern**: Uses wildcards to match multiple files/directories

#### Options

- `--log-level {DEBUG,INFO,WARNING,ERROR}` - Set logging verbosity (default: INFO)
- `--log-file FILE` - Write logs to a file (in addition to console output)

### Examples

```bash
python3 scripts/fetch_artifacts.py
python3 scripts/fetch_artifacts.py repository
python3 scripts/fetch_artifacts.py repository share aps
python3 scripts/fetch_artifacts.py "**/artifacts-25.yaml"
python3 scripts/fetch_artifacts.py repository --log-level DEBUG
python3 scripts/fetch_artifacts.py repository --log-file download.log
```

### Environment Variables

- `ACS_VERSION` - Alfresco Content Services version (default: "25")
- `NEXUS_USERNAME` - Nexus repository username
- `NEXUS_PASSWORD` - Nexus repository password
- `MAVEN_FQDN` - Maven repository FQDN (default: "nexus.alfresco.com")
- `MAVEN_REPO` - Full Maven repository URL

For authentication check out [nexus authentication](#nexus-authentication)

## Known issues

- When building `all` target with `make`, which is meant to build only `acs`, the
  fetching script will also try to download the artifacts related to `aps`.
  Build will proceed as it will use the `default` bake target which points to
  `enterprise` and `community` targets.

## Release

- Ensure that the
  [supported-matrix](https://github.com/Alfresco/alfresco-updatecli/blob/master/deployments/values/supported-matrix.yaml)
  reflects the status of the currently released Alfresco products and update if
  necessary before proceeding.
- Ensure that in every `artifacts-*.yaml` file for both `repository` and
  `share` images, the `updatecli_amps_release_branch` key refer the latest minor
  version for every major acs version by inspecting the currently available
  release branches in [acs-packaging](https://github.com/Alfresco/acs-packaging)
  repository.
- Run the [updatecli
  workflow](https://github.com/Alfresco/alfresco-dockerfiles-bakery/actions/workflows/bumpVersions.yml)
  and review the changes.
- Agree on a name for the release and make sure to add it to the release notes.

Once everything has been merged to master, you can proceed to create a release with:

```sh
gh release create v0.2.0 -t "🍞 Fougasse v0.2.0" --generate-notes -d
```

Finally review the autogenerated release notes, remove not so interesting
changes (e.g. GHA tuning and dependabot), highlight most interesting ones for
the end users and publish the release.
