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
