# Alfresco digital workspace image

## Description

This Docker file is used to build an Alfresco digital workspace.

## Building the image

Make sure all required artifacts are present in the build context `adf-apps/adw/`.
You can put them manually in the `adf-apps/adw/` folder (for example if that's a
custom module of yours), or use the script `./scripts/fetch-artifacts.sh` to
download them from Alfresco's Nexus.

Then, you can build the image from the root of this git repository with the
following command:

```bash
docker buildx bake adw
```

## Running the image

:warning: `BASE_PATH` should still be provided as a env or directly changed
inside `default.conf.template`

To run the image it is recommended to review and provide the json config file.
Example configuration of that file is stored on this repository:
`test/configs/adw.json`.

:warning: It is recommended to get your own config file because it may differ
from the one stored on this repo. To get the config file either extract it from
the artifact zip or copy it from the running image with:

```sh
docker run --name temp-container -d localhost/alfresco/alfresco-digital-workspace:latest && \
docker cp temp-container:/usr/share/nginx/html/app.config.json ./adw.config.json && \
docker stop temp-container && \
docker rm temp-container
```

There is few approaches you can use to provide a config
file e.g.

### Providing app.config.json at run time using docker compose

1. Point config file to specific path on container:

```yaml
volumes:
- ./adw.config.json:/usr/share/nginx/html/app.config.json
```

### Providing app.config.json at run time using helm
1. Change the `adw.config.json` according to needs
2. Create configmap from it, in the same namespace where acs is being deployed

```sh
kubectl create configmap adw-config --from-file=app.config.json=adw.config.json
```

3. Mount created configmap to the adw deployment:

```yaml
alfresco-digital-workspace:
  image:
    repository: localhost/alfresco/alfresco-digital-workspace
    tag: latest
  volumeMounts:
    - name: app-config
      mountPath: /usr/share/nginx/html/app.config.json
      subPath: app.config.json
  volumes:
    - name: app-config
      configMap:
        name: adw-config
        items:
          - key: app.config.json
            path: app.config.json
```