# Alfresco control center image

## Description

This Docker file is used to build an Alfresco control center.

## Building the image

Make sure all required artifacts are present in the build context `adf-apps/acc/`.
You can put them manually in the ``adf-apps/acc/` folder (for example if that's a
custom module of yours), or use the script `./scripts/fetch-artifacts.sh` to
download them from Alfresco's Nexus.

Then, you can build the image from the root of this git repository with the
following command:

```bash
docker buildx bake acc
```

## Running the image

### Alfresco control center configuration

Example set of variables for docker-compose file:

```yaml

alfresco-control-center:
    image: localhost/alfresco-control-center:YOUR-TAG
    environment:
      BASE_PATH: ./

```

| Property             | Description                                                                                 | Default value |
|----------------------|---------------------------------------------------------------------------------------------|---------------|
| BASE_PATH            |                                                                                             | `./`          |


> If the image is meant to be used with the Alfresco Content Services Helm
> chart, you can use other [higher level means of
> configuration](https://github.com/Alfresco/alfresco-helm-charts/blob/main/charts/alfresco-adf-app/README.md).
