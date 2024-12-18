# Alfresco Sync Service image

## Description

:warning: Current version of this Dockerfile will start separate processes for
entrypoint and for `syncservice.sh` script due to handling of the scripts on
upstream repo.

This Docker file is used to build an Alfresco Sync Service image.

## Building the image

Make sure all required artifacts are present in the build context `sync/`.
You can put them manually in the `sync/` folder (for example if that's a
custom module of yours), or use the script `./scripts/fetch-artifacts.py` to
download them from Alfresco's Nexus.

Then, you can build the image from the root of this git repository with the
following command:

```bash
docker buildx bake sync
```

## Running the image

### Alfresco Sync Service configuration

Properties can be added in the `JAVA_OPTS` environment variable to the
container.

For example, to set the repository URL, you can use the following environment
variable:

```bash
docker run -e JAVA_OPTS="-Drepo.hostname=alfresco" \
  localhost/alfresco/alfresco-sync-service:latest
```

> Set of required properties: [sync]

> If the image is meant to be used with the Alfresco Content Services Helm
> chart, you can use other [higher level means of
> configuration](https://github.com/Alfresco/alfresco-helm-charts/blob/main/charts/alfresco-sync-service/README.md).

[sync]: https://support.hyland.com/r/Alfresco/Alfresco-Sync-Service/5.1/Alfresco-Sync-Service/Configure/Overview/Required-properties
