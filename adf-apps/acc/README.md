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

:warning: `BASE_PATH` should still be provided as a env or directly changed
inside default.conf.template

To run the image it is recommended to review and provide the json config file.
Example configuration of that file is stored on this repository:
`test/configs/acc.json`. There is few approaches you can use to provide a config
file:

### Providing app.config.json at build time:

1. Copy `test/configs/acc.json` into `adf-apps/acc/`
2. Change the file according to needs
3. Add this line to a Dockerfile (after the unzip command):

```Dockerfile
COPY app.config.json /usr/share/nginx/html/app.config.json
```

4. Build new image

### Providing app.config.json at run time using docker compose:

1. Point config file to specific path on container:

```yaml
volumes:
- ./configs/acc.json:/usr/share/nginx/html/app.config.json
```

### Providing app.config.json at run time using helm:

1. Change the `test/configs/acc.json` according to needs
2. Create configmap from it, in the same namespace where acs is being deployed

```sh
kubectl create configmap acc-config --from-file=app.config.json=test/configs/acc.json
```

3. Mount created configmap to the acc deployment:

```yaml
alfresco-control-center:
  image:
    repository: localhost/alfresco/alfresco-control-center
    tag: latest
  env:
    BASE_PATH: ./
  volumeMounts:
    - name: app-config
      mountPath: /usr/share/nginx/html/app.config.json
      subPath: app.config.json
  volumes:
    - name: app-config
      configMap:
        name: acc-config
        items:
          - key: app.config.json
            path: app.config.json
```
