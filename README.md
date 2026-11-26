# Alfresco Dockerfiles Bakery 🍞

[![release](https://img.shields.io/github/v/release/Alfresco/alfresco-dockerfiles-bakery?display_name=release)](https://github.com/Alfresco/alfresco-dockerfiles-bakery/releases/latest)
[![CI](https://github.com/Alfresco/alfresco-dockerfiles-bakery/actions/workflows/build_and_test.yml/badge.svg)](https://github.com/Alfresco/alfresco-dockerfiles-bakery/actions/workflows/build_and_test.yml)
[![CI Community](https://github.com/Alfresco/alfresco-dockerfiles-bakery/actions/workflows/build_forks.yml/badge.svg)](https://github.com/Alfresco/alfresco-dockerfiles-bakery/actions/workflows/build_forks.yml)

As outlined in the [Hyland Alfresco support
policy](https://docs.hyland.com/r/Alfresco/Alfresco-Content-Services/23.7/Alfresco-Content-Services/Install/Overview/Install-and-deploy-methods),
pre-built container images are intended as reference for creating your own
customized images, incorporating deployment guidelines, security best practices,
and any necessary custom extensions. While this policy remains unchanged, we are
supporting the community further by open-sourcing the Alfresco Dockerfiles
Bakery, a tool designed to simplify the deployment of the Alfresco platform and
assist you in building tailored container images, with the help of [Docker
Bake](https://docs.docker.com/build/bake/).

> [!NOTE]
> We are working towards Bakery 1.0, and the first step is the `bakery` Go CLI.
> The current version replaces the Makefile and scripts used to work with this
> repository, so use it for every task you ran with them before.
> In its final form, you won't need to clone this repository to build the
> images: the CLI alone will build them, driven by a configuration file with a
> stable interface.

- [Alfresco Dockerfiles Bakery 🍞](#alfresco-dockerfiles-bakery-)
  - [Prerequisites](#prerequisites)
    - [Installing the bakery CLI](#installing-the-bakery-cli)
      - [Building from source](#building-from-source)
    - [Vagrant alternative](#vagrant-alternative)
    - [Nexus authentication](#nexus-authentication)
  - [Getting started quickly](#getting-started-quickly)
  - [Migrating from the Makefile](#migrating-from-the-makefile)
  - [Customizing the images](#customizing-the-images)
    - [Customizing the Alfresco Content Repository image](#customizing-the-alfresco-content-repository-image)
    - [Customizing the Share image](#customizing-the-share-image)
    - [Customizing the Community Batch Indexing image](#customizing-the-community-batch-indexing-image)
  - [Supported Architectures](#supported-architectures)
    - [Targeting a specific architecture](#targeting-a-specific-architecture)
    - [Multi-arch images](#multi-arch-images)
  - [Building older versions](#building-older-versions)
  - [Testing locally](#testing-locally)
    - [Testing with helm](#testing-with-helm)
    - [Testing with docker compose](#testing-with-docker-compose)
  - [Security scanning](#security-scanning)
  - [Software Bill of Materials](#software-bill-of-materials)
  - [Build provenance](#build-provenance)
  - [Fetching artifacts](#fetching-artifacts)
    - [Usage](#usage)
    - [Arguments](#arguments)
      - [Targets (optional)](#targets-optional)
      - [Options](#options)
    - [Examples](#examples)
    - [Sources](#sources)
    - [Environment Variables](#environment-variables)
  - [Known issues](#known-issues)
  - [Release](#release)

## Prerequisites

Building images requires the following tools:

- A recent enough Docker installation (with `buildx` support)
- The `bakery` CLI, see [Installing the bakery CLI](#installing-the-bakery-cli)
- Credentials to access the Alfresco artifacts (Nexus server), if building
  Enterprise images

Alternatively, you can use the provided [Vagrantfile](Vagrantfile) to create a
dedicated VM with all the required tools installed. This is useful if you want
to build the images without installing the tools on your local machine.

### Installing the bakery CLI

The `bakery` CLI builds the images defined in this repository. It runs on
Linux, macOS and Windows, and works on the checkout it is run from (or the one
given with `--dir`).

On Linux and macOS, download the latest release for your platform and move the
binary to a folder already in your `PATH`, such as `/usr/local/bin`:

```sh
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m | sed 's/x86_64/amd64/; s/aarch64/arm64/')
curl -fsSL "https://github.com/Alfresco/alfresco-dockerfiles-bakery/releases/latest/download/bakery_${OS}_${ARCH}.tar.gz" | tar -xz bakery
sudo mv bakery /usr/local/bin/
bakery --version
```

With `wget`, replace the `curl` line with:

```sh
wget -qO- "https://github.com/Alfresco/alfresco-dockerfiles-bakery/releases/latest/download/bakery_${OS}_${ARCH}.tar.gz" | tar -xz bakery
```

To install the CLI from a specific release, for example the one matching your
checkout, replace `latest/download` in the URL with `download/<tag>`, such as
`download/v0.17.0`. Each release also has a `bakery_checksums.txt` file with the
SHA-256 of every archive.

On Windows, download `bakery_windows_amd64.zip` (or `bakery_windows_arm64.zip`)
from the [releases
page](https://github.com/Alfresco/alfresco-dockerfiles-bakery/releases),
extract `bakery.exe` and put it in a folder listed in your `PATH`.

Run `bakery --help` to list the commands, and `bakery build --help` for the
available targets and options.

#### Building from source

With Go installed, you can build the CLI from your checkout instead, so it
always matches the recipes you build. `go install` puts the binary in
`$(go env GOPATH)/bin`, which must be in your `PATH`:

```sh
cd cli && go install ./bakery
```

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

The provisioning also installs the `bakery` CLI, so you can proceed running the
`bakery` commands as described later in this document from the `/vagrant`
folder.

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

Credentials are resolved from your `~/.netrc` file by the host of each source, so
a `~/.netrc` may hold an entry for every host you fetch from. Sources whose host
has no matching entry are accessed anonymously. To point the build at your own
Maven repositories, see [Bring your own repository](docs/bring-your-own-repository.md).

## Getting started quickly

If you do not plan on applying specific customizations but just want to get
Alfresco images updated (e.g. with the latest OS security patches), you can
simply run the command below from the root of this project:

```sh
bakery build enterprise
```

or for Community edition:

```sh
bakery build community
```

This command fetches the required artifacts and builds locally all the docker
images this project offers.

For more information on the available images, browse the top level folders,
excluding `artifacts_cache`, `scripts` and `test`.

For more information on the available targets, run:

```sh
bakery build --help
```

The build can be customized with these options. Each one can also be set with
the environment variable in brackets:

- `--acs-version` (`ACS_VERSION`): The ACS major version to build, see
  [Building specific ACS versions](#building-specific-acs-versions)
- `--aps-version` (`APS_VERSION`): The APS major version to build
- `--registry` (`REGISTRY`): The registry where the images will be pushed. The
  CLI runs `docker login` and asks for confirmation before pushing. Unset or
  `localhost` loads the images locally.
- `--namespace` (`REGISTRY_NAMESPACE`): The namespace where the images will be
  pushed (e.g. REGISTRY/REGISTRY_NAMESPACE/IMAGE_NAME:TAG)
- `--tag` (`TAG`): The tag to use for the images (default is the version of the
  artifact each image packages)
- `--yes`: Push without asking for confirmation, e.g. in CI
- `--no-cache` (`BAKE_NO_CACHE`): Disable the cache during the build process
- `--no-sbom` (`BAKE_NO_SBOM`): Do not attach an SBOM attestation to the images
  when pushing them to a registry. See [Software Bill of
  Materials](#software-bill-of-materials) for more information.
- `--provenance` (`BAKE_PROVENANCE`): Provenance attestation to attach to the
  images when pushing them to a registry, disabled (`false`) by default. Set to
  `mode=min` or `mode=max` to describe your own build. See [Build
  provenance](#build-provenance) for more information.
- `TARGETARCH`: The architecture to build the images for (default is the
  architecture of the system where the build is run). See [Supported
  Architectures](#supported-architectures) for more information.

For example, to build multi-arch images for ARM64 and X86_64 and push them to a
custom registry, you can run the following command:

```sh
export TARGETARCH=linux/amd64,linux/arm64
bakery build all --registry myecr.domain.tld --namespace myalfrescobuilds
```

## Migrating from the Makefile

The `bakery` CLI replaces the Makefile and the Python scripts. The environment
variables they read (`ACS_VERSION`, `REGISTRY`, `TAG`, `GRYPE_OPTS`, ...) still
work.

| Before                                         | Now                             |
| ---------------------------------------------- | ------------------------------- |
| `make <target>` (e.g. `make enterprise`)       | `bakery build <target>`         |
| `GRYPE_ONBUILD=true make <target>`             | `bakery build <target> --grype` |
| `make grype GRYPE_TARGET=<target>`             | `bakery grype <target>`         |
| `make clean`                                   | `bakery clean -f`               |
| `make clean_caches`                            | `bakery clean --caches`         |
| `python3 scripts/fetch_artifacts.py [targets]` | `bakery fetch [targets]`        |
| `python3 scripts/print_artifact_versions.py`   | `bakery versions`               |

## Customizing the images

All the images running a Java web application are built on the Alfresco base
Tomcat image. The servlet container they embed is configured with the `TOMCAT_*`
environment variables documented in [tomcat/README.md](tomcat/README.md).

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

These sources use named Docker Bake build contexts with the folders above as
their defaults. Each source can be customized independently with `--set`:

```sh
docker buildx bake repository \
  --set repository.contexts.repo_libs=./custom-libs
```

Repository contexts are `repo_distribution`, `repo_amps`, `repo_amps_edition`,
`repo_libs`, and `repo_simple_modules`. The replacement directory is used as the
root of the corresponding build context. `repo_distribution` supplies the
Alfresco Content Services distribution zip, which lets a build source the
distribution from a local folder instead of the in-tree `repository/distribution`.

#### Overriding a build context source

Each of these inputs is a named Docker Bake build context, so you can supply it
from your own source instead of the in-tree default. Depending on how you supply
the files, there are two behaviours:

- **Merge with the fetched defaults** — add your files to the in-tree default
  folders (`repository/amps`, `repository/amps_<edition>`, `repository/libs`,
  `repository/simple_modules`). `bakery build` (or `bakery fetch`) fills those
  same folders with the Nexus defaults such as `share-services` and `aos`, so
  your files land **alongside** them and both end up in the image.
- **Replace a context wholesale** — point a context at a *different* source with
  `--set`. The replacement becomes the **root** of the context, so it must
  contain every file you want for that input; it does **not** merge with the
  in-tree folder, and any default it omits (e.g. `share-services`, `aos`) is
  dropped.

The table below lists each repository context, what you put in it, and where the
files land in the built image:

| Scenario | Context | Put in the folder | Lands in the image |
| --- | --- | --- | --- |
| Add / override an AMP module (both editions) | `repo_amps` | `*.amp` | installed into `alfresco.war` |
| Add / override an edition-only AMP | `repo_amps_edition` | `*.amp` (community/enterprise) | installed into `alfresco.war` |
| Add / override a Tomcat library | `repo_libs` | `*.jar` (e.g. JDBC drivers) | `/usr/local/tomcat/lib/` |
| Add / override a simple module | `repo_simple_modules` | `*.jar` | `/usr/local/tomcat/modules/platform/` |

For example, supply your own AMPs (the folder must hold every AMP the image
should have), Tomcat libraries and simple modules from local folders:

**Add or override AMPs** (both editions) — installed into `alfresco.war`:

```sh
docker buildx bake repository \
  --set repository.contexts.repo_amps=./my-amps
```

**Add or override an edition-only AMP** (`repository/amps_community` or
`repository/amps_enterprise`) — installed into `alfresco.war`:

```sh
docker buildx bake repository \
  --set repository.contexts.repo_amps_edition=./my-edition-amps
```

**Add or override a Tomcat library** (e.g. a JDBC driver) — placed in
`/usr/local/tomcat/lib/`:

```sh
docker buildx bake repository \
  --set repository.contexts.repo_libs=./my-libs
```

**Add or override a simple module** (platform JAR) — placed in
`/usr/local/tomcat/modules/platform/`:

```sh
docker buildx bake repository \
  --set repository.contexts.repo_simple_modules=./my-simple-modules
```

You can also combine them in a single build:

```sh
docker buildx bake repository \
  --set repository.contexts.repo_amps=./my-amps \
  --set repository.contexts.repo_libs=./my-libs \
  --set repository.contexts.repo_simple_modules=./my-simple-modules
```

A local folder is only one of the source types a Docker Bake named context
accepts. You can also point a context at a Git URL (optionally with a ref and
subdirectory), an HTTP tarball URL, or an image reference. For example, to pull
the AMPs from a Git repository at a given tag and subdirectory:

```sh
docker buildx bake repository \
  --set repository.contexts.repo_amps=https://github.com/myorg/my-amps.git#v1.0.0:amps
```

For the exact syntax of each source type, see the Docker Bake documentation on
[named contexts](https://docs.docker.com/build/bake/reference/#targetcontexts)
and [build contexts](https://docs.docker.com/build/building/context/).

### Customizing the Share image

The Share image can be customized by adding files into specific folders:

- Alfresco Module Packages (AMPs) files in the [amps](share/amps/README.md)
  folder
- Share Simple Module (JAR) files in the
  [simple_modules](share/simple_modules/README.md) folder

These sources use named Docker Bake build contexts with the folders above as
their defaults. Each source can be customized independently with `--set`:

```sh
docker buildx bake share \
  --set share.contexts.share_amps=./custom-share-amps
```

Share contexts are `share_distribution`, `share_amps`, and
`share_simple_modules`. The replacement directory is used as the root of the
corresponding build context. `share_distribution` supplies the Alfresco Share
distribution zip, which lets a build source the distribution from a local folder
instead of the in-tree `share/distribution`.

### Customizing the Community Batch Indexing image

The Community Batch Indexing image (`search_batch_indexing`) packages the
Alfresco Elasticsearch community connector for Elasticsearch-based Community
Edition deployments. Batch indexing is currently available for ACS 26.

Set `ACS_VERSION` to select the ACS version when building directly. For example,
build the batch indexing image for ACS 26:

```sh
ACS_VERSION=26 docker buildx bake search_batch_indexing
```

To build all Community Edition images for a selected ACS version, use:

```sh
bakery build community --acs-version 26
```

For ACS 23 and ACS 25, the `community` group builds the Solr-based Search
Service instead of batch indexing.

Runtime behaviour can be controlled via environment variables passed to the
container and via standard Spring externalized configuration (e.g. mounted config
files). See [search/community/README.md](search/community/README.md) for the full list of supported variables and customization options.

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
bakery build all
```

To build just a specific image you'll need to use `docker buildx bake`
directly (after `bakery fetch` for its artifacts), but the `TARGETARCH`
environment variable also works:

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
bakery build all --registry myecr.domain.tld
```

It's important to note that building multi-arch images requires the use of
Docker BuildKit, which is enabled by default in Docker 20.10 and later and
also requires images to be pushed to a registry that supports multi-arch.

:warning: Multi-arch build cannot be loaded into the local docker image cache.
This is due to a limitation of the `docker` exporter in BuildKit.
In order to produce multi-arch images one needs to:

- Set the target registry with `--registry` (or `REGISTRY`)
- Set the target namespace with `--namespace` (or `REGISTRY_NAMESPACE`)

The `bakery` CLI handles the authentication part for you:

```sh
export TARGETARCH=linux/amd64,linux/arm64
bakery build repository --registry myecr.domain.tld --namespace myalfrescobuilds
```

You can also run bake directly but you need to be sure to have done the
authentication before running the `docker buildx bake` command with an
additional argument to tell the tool to push the images to the registry:

```sh
export REGISTRY=myecr.domain.tld REGISTRY_NAMESPACE=myalfrescobuilds TARGETARCH=linux/amd64,linux/arm64
docker buildx bake repository --set *.output=type=registry,push=true
```

## Building specific ACS versions

Versions of artifacts being downloaded specific to the ACS version are defined
in `artifacts-XX.yaml` files for each component.

To build a specific ACS version, pass `--acs-version` to `bakery` or the
`ACS_VERSION` env to either `bakery` or `docker buildx bake`.

- ACS 26 (current default) - `ACS_VERSION=26` - Will use `artifacts-26.yaml` files
- ACS 25  - `ACS_VERSION=25` - Will use `artifacts-25.yaml` files
- ACS 23  - `ACS_VERSION=23` - Will use `artifacts-23.yaml` files

```sh
bakery build enterprise --acs-version 23
```

```sh
ACS_VERSION=23 docker buildx bake enterprise
```

Tomcat values are selected automatically from `docker-bake.hcl` based on
`ACS_VERSION`.

If needed, you can still override Tomcat values explicitly using `--set`.

Before switching build to other version you can clean the artifacts using
`bakery clean` then fetch correct version with e.g.:

```sh
bakery clean -f
bakery fetch --acs-version 23
```

Superseded versions of an artifact are also pruned automatically from its
target folder as soon as the new version is fetched, so re-running with a
different `ACS_VERSION` (or after bumping a version in an `artifacts-XX.yaml`
file) without `bakery clean` first will not leave stale files behind.

`bakery clean --caches` also prunes the Docker build cache and empties the
`artifacts_cache` download cache.

Artifacts set in the artifacts file are fetched from the Nexus repository and
their checksum is verified, provided the artifact has a checksum value which is
a concatenation of the algorithm and optionally the checksum in the format
`<algorithm>:<checksum>`. If the checksum is not provided, the CLI will
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

Images built from `java_base` use
`docker.io/rockylinux/rockylinux:9-minimal`, set through the
`IMAGE_BASE_LOCATION` bake variable. [`.grype.yaml`](.grype.yaml) skips
`java-archive` packages, so application JARs are left out. Recorded results are
in [docs/security-scanning.md](docs/security-scanning.md).

If you want to run the security scan manually, you can use the following command:

```sh
bakery grype repository
```

The target accepts any `docker-bake.hcl` target or group name (e.g. `repository`,
`share`, `community`, `enterprise`). Without a target, `GRYPE_TARGET` is used,
and without either the default group is scanned.

You can pass `--grype-opts` (or `GRYPE_OPTS`) to override the default options
passed to Grype (`-f high --only-fixed --ignore-states wont-fix`), which exit
with a non-zero status if any vulnerability greater than high is found and
filter out known issues for which a fix is not available (yet or ever).

Set `--grype-output-dir` (or `GRYPE_OUTPUT_DIR`) to write each image's scan
output to a file in that directory instead of printing it to stdout, and
`--grype-output-format` (or `GRYPE_OUTPUT_FORMAT`) to pick the format (see
Grype's `-o`/`--output` flag), e.g. to collect SARIF reports for upload
elsewhere:

```sh
bakery grype repository --grype-opts "--only-fixed --ignore-states wont-fix" --grype-output-dir sarif --grype-output-format sarif
```

You can also run grype automatically at the end of the build process with
`--grype` (or `GRYPE_ONBUILD`):

```sh
bakery build all --grype
```

## Software Bill of Materials

Images pushed to a registry carry an SPDX Software Bill of Materials, attached
as a [BuildKit SBOM
attestation](https://docs.docker.com/build/metadata/attestations/sbom/), with
one attestation per image and per platform.

Getting an SBOM requires a registry to push to, since the `docker` exporter used
when loading images locally cannot carry attestations:

```sh
bakery build repository --registry myecr.domain.tld --namespace myalfrescobuilds
```

When calling bake directly instead of going through the `bakery` CLI, pass
`--sbom=true` yourself:

```sh
docker buildx bake repository --set *.output=type=registry,push=true --sbom=true
```

Pass `--no-sbom` (or set `BAKE_NO_SBOM=1`) to turn SBOM generation off, for instance when targeting a
registry which does not support OCI attestation manifests.

To retrieve the SBOM of an image (the registry below is a placeholder, use your
own):

```sh
docker buildx imagetools inspect myecr.domain.tld/myalfrescobuilds/alfresco-content-repository:<tag> --format '{{ json .SBOM }}'
```

For a multi-arch image the output is keyed by platform, so pick one to get a
plain SPDX document:

```sh
docker buildx imagetools inspect myecr.domain.tld/myalfrescobuilds/alfresco-content-repository:<tag> --format '{{ json (index .SBOM "linux/amd64").SPDX }}'
```

The resulting document can be fed to any SPDX-aware tooling, for example to scan
it without pulling the image:

```sh
docker buildx imagetools inspect myecr.domain.tld/myalfrescobuilds/alfresco-content-repository:<tag> --format '{{ json (index .SBOM "linux/amd64").SPDX }}' > sbom.spdx.json
grype sbom:sbom.spdx.json
```

## Build provenance

Provenance records how and where an image was built: the repository and commit
it was built from, the job which built it and the build parameters used. It is
attached to images pushed to a registry as a [BuildKit provenance
attestation](https://docs.docker.com/build/metadata/attestations/slsa-provenance/),
one attestation per image and per platform. This repository's CI builds attach
it in `mode=max`.

Provenance is disabled by default, since a record only describes the build which
produced it, and says nothing to whoever consumes the image unless they know the
build environment it points at. If you build your own images and want
provenance, describe your own build with `--provenance` (or `BAKE_PROVENANCE`):

```sh
bakery build repository --registry myecr.domain.tld --namespace myalfrescobuilds --provenance mode=max
```

As with the SBOM, this requires a registry to push to, since the `docker`
exporter used when loading images locally cannot carry attestations. When
calling bake directly instead of going through the `bakery` CLI, pass
`--provenance` yourself:

```sh
docker buildx bake repository --set *.output=type=registry,push=true --provenance=mode=max
```

Use `mode=min` for the invocation details only, or leave provenance disabled
when targeting a registry which does not support OCI attestation manifests.

To retrieve the provenance of an image, picking one platform out of the
per-platform map (the registry below is a placeholder, use your own):

```sh
docker buildx imagetools inspect myecr.domain.tld/myalfrescobuilds/alfresco-content-repository:<tag> --format '{{ json (index .Provenance "linux/amd64").SLSA }}'
```

The interesting fields of the resulting [SLSA
v1](https://slsa.dev/spec/v1.0/provenance) statement are
`runDetails.builder.id`, which points at the CI job which produced the image,
and the `vcs:source` / `vcs:revision` build request arguments, which hold the
repository and the commit it was built from. The `mode=max` statement also
carries every build argument, the Dockerfile itself and the resolved base image
digests. To check which repository, commit and job an image comes from:

```sh
docker buildx imagetools inspect myecr.domain.tld/myalfrescobuilds/alfresco-content-repository:<tag> \
  --format '{{ json (index .Provenance "linux/amd64").SLSA }}' \
  | jq '{builder: .runDetails.builder.id,
         source: .buildDefinition.externalParameters.request.root.request.args["vcs:source"],
         revision: .buildDefinition.externalParameters.request.root.request.args["vcs:revision"]}'
```

## Fetching artifacts

`bakery build` downloads the artifacts each target needs before building. To
only download artifacts from the Alfresco Nexus repository, based on the
`artifacts-XX.yaml` files, use `bakery fetch`.

### Usage

```bash
bakery fetch [targets...] [options]
```

### Arguments

#### Targets (optional)

You can specify one or more targets, relative to the repository root:

- **No arguments**: Processes the entire repository (only files matching
  `artifacts-<ACS_VERSION>.yaml`)
- **Directory path**: Searches for `artifacts-<ACS_VERSION>.yaml` files in the
  specified directory and its subfolders
- **File path**: Processes a specific artifact YAML file
- **Glob pattern**: Uses wildcards to match multiple files, `**` included

#### Options

- `--acs-version` - ACS version of the manifests to fetch (default: `26`)
- `--log-level {DEBUG,INFO,WARNING,ERROR}` - Set logging verbosity (default: INFO)
- `--log-file FILE` - Write logs to a file (in addition to console output)

### Examples

```bash
bakery fetch
bakery fetch repository
bakery fetch repository share aps
bakery fetch "**/artifacts-26.yaml"
bakery fetch repository --log-level DEBUG
bakery fetch repository --log-file download.log
```

`bakery versions` prints the map of artifact versions which `docker-bake.hcl`
uses to tag the images, for use with `docker buildx bake` directly:

```bash
ARTIFACT_VERSIONS="$(bakery versions)" docker buildx bake repository
```

### Sources

Each artifact in an `artifacts-*.yaml` file declares a `source` that must be
defined in [`sources.yaml`](sources.yaml) at the root of this repository. A
source is the root URL of a Maven repository; artifacts are fetched from it
using the standard Maven GAV layout. Credentials are never stored in
`sources.yaml`: they are resolved from your `~/.netrc` file by host, and anonymous
access is used when nothing matches. In CI the `~/.netrc` is written by the
[`setup-netrc`](.github/actions/setup-netrc/action.yml) action from host-keyed secrets.

To fetch Alfresco artifacts from your own Maven repositories instead of Nexus,
see [Bring your own repository](docs/bring-your-own-repository.md).

### Environment Variables

- `ACS_VERSION` - Alfresco Content Services version (default: "26")
- `SOURCES_FILE` - Path to the sources definition file (default: `sources.yaml`)
- `NETRC` - Path to the credentials file (default: `~/.netrc`)

For authentication check out [nexus authentication](#nexus-authentication)

## Known issues

- When building the `all` target, which is meant to build only `acs`, the
  CLI will also try to download the artifacts related to `aps`.
  Build will proceed as it will use the `default` bake target which points to
  `enterprise` and `community` targets.

## Release

- Check if acs and aps charts need to be updated in
  `.github/actions/acs-deployment` and `.github/actions/aps-deployment`  
  respectively.
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
- Merge all the eventual dependabot and updatecli PRs (for nginx and tomcat base
  images)
- Agree on a name for the release and make sure to add it to the release notes.

Once everything has been merged to master, you can proceed to create a release with:

```sh
gh release create v0.2.0 -t "🍞 Fougasse v0.2.0" --generate-notes -d
```

Finally review the autogenerated release notes, remove not so interesting
changes (e.g. GHA tuning and dependabot), highlight most interesting ones for
the end users and publish the release.

Publishing the release triggers the [release
workflow](.github/workflows/on-release.yml), which attaches the `bakery` CLI
binaries for Linux, macOS and Windows (amd64 and arm64) to it.
