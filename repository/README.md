# Alfresco Content Repository image

## Description

This Docker file is used to build an Alfresco Content Repository image.

## Building the image

Make sure all required artifacts are present in the build context `repository/`.
You can put them manually in the `repository/` folder (for example if that's a
custom module of yours), or use the script `./scripts/fetch-artifacts.sh` to
download them from Alfresco's Nexus.

Then, you can build the image from the root of this git repository with the
following command:

```bash
docker buildx bake repository
```

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
