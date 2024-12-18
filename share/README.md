# Alfresco share image

## Description

This Docker file is used to build an Alfresco share image.

## Building the image

Make sure all required artifacts are present in the build context `share/`.
You can put them manually in the `share/` folder (for example if that's a
custom module of yours), or use the script `./scripts/fetch-artifacts.py` to
download them from Alfresco's Nexus.

Then, you can build the image from the root of this git repository with the
following command:

```bash
docker buildx bake share
```

## Running the image

### Alfresco share configuration

All preperties you would normally add in the alfresco-global.properties file can
be added in the `JAVA_OPTS` environment variable to the container.

For example, to set the database URL, you can use the following environment
variable:

```bash
docker run -e JAVA_OPTS="-Dalfresco.host=localhost" \
  alfresco-share:mytag
```

Example set of variables for docker-compose file:

```yaml

alfresco-connector-ms365:
    image: localhost/alfresco-share:YOUR-TAG
    environment:
      JAVA_OPTS: ""
      REPO_HOST: alfresco
      REPO_PORT: 8080
      CSRF_FILTER_REFERER:
      CSRF_FILTER_ORIGIN:
      USE_SSL: false

```

- `JAVA_OPTS` - A set of properties that are picked up by the JVM inside the container
- `REPO_HOST` - Share needs to know how to register itself with Alfresco. The default value is `localhost`
- `REPO_PORT` - Share needs to know how to register itself with Alfresco. The default value is `8080`
- `CSRF_FILTER_REFERER` -	CSRF Referrer
- `CSRF_FILTER_ORIGIN` - CSRF Origin
- `USE_SSL` - Enables ssl use if set to `true`. The default value is `false`


> If the image is meant to be used with the Alfresco Content Services Helm
> chart, you can use other [higher level means of
> configuration](https://github.com/Alfresco/alfresco-helm-charts/blob/main/charts/alfresco-share/README.md).
