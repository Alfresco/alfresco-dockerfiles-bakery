# Alfresco Docker images builder

This projects aims at providing a quick and easy to build and maintain Alfresco
Docker images.

## Getting started quickly

If you do not plan on applying specific customizations but just want to get
Alfresco images updated (e.g. with the latest OS security patches), you can
simply run the command below from the root of this project:

```bash
make all
```

This command will build locally all the docjker images this project offers.
At the time of writing, these are:

* Alfresco Content Repository (Enterprise) 23.2.2
* Alfresco Search Enterprise 4.4.0
* Alfresco Transformation Services 4.1.3

## Building the specific images

If you want to build a specific image, you can run one of the following make target:

* repo: build the Alfresco Content Repository image
* search_enterprise: build the Alfresco Search Enterprise images
* ats: build the Alfresco Transformation Service images 

## Customizing the images

### Customizing the Alfresco Content Repository image

The Alfresco Content Repository image can be customized by adding different
types of files in the right locations:

* Alfresco Module Packages (AMPs) files in the [amps}(repository/amps/README.md) folder
* Additional JAR files for the JRE in the [libs](repository/libs/README.md) folder

## Architecture choice

The image architecture defaults to the building system's architecture when the
`TARGET_ARCH` is empty. To modify it, you need to adjust variable in the Bake
file to a specific architecture, such as `linux/amd64`.

```

variable "TARGET_ARCH" {
  default = "linux/amd64"
}

```

Setting the var to a `linux/arm64` or `linux/amd64` will result in creating
images that are currently supporting multi platform. There is also other way to
set the target architecture:

```sh

docker buildx bake --set *.platform=linux/arm64

```

Simply use the above command to set the target platform for every image.
Warning: currently we are not supporting every image on `linux/arm64` arch. 

Other way to override `TARGET_ARCH` using the Makefile: 

```makefile
arm64_supported: docker-bake.hcl prepare_all
	@echo "Building all supported images for arm64"
	@export TARGET_ARCH="linux/arm64"
	@docker buildx bake --no-cache --progress=plain java_base
``` 

```sh

make arm64_supported

```
