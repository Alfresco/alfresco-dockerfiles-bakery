# Runtime variables

Sets of variables configurable with your docker image

## ms365

```yaml

alfresco-connector-ms365:
    image: localhost/alfresco-ooi-service:YOUR-TAG
    environment:
      JAVA_OPTS: "-Dalfresco.base-url=http://alfresco:8080"
      ALFRESCO_ADMIN_PASSWORD: admin
      ALFRESCO_ADMIN_USERNAME: admin
      ALFRESCO_DEPLOYMODEL_ENABLED: 'true'
      ALFRESCO_DEPLOYMODEL_RETRY_INTERVAL: '30000'
      ALFRESCO_DEPLOYMODEL_TIMEOUT: '960000'

```

- `JAVA_OPTS` - Additional java options
- `ALFRESCO_ADMIN_USERNAME` - The username for the Alfresco admin account used to authenticate to the repository.
- `ALFRESCO_ADMIN_PASSWORD` - The password for the Alfresco admin account used to authenticate to the repository.
- `ALFRESCO_DEPLOYMODEL_ENABLED` - Enables or disables the deployment of models. Set to `'true'` to enable model deployment, or `'false'` to disable it.
- `ALFRESCO_DEPLOYMODEL_RETRY_INTERVAL` - The interval (in milliseconds) between retry attempts for model deployment. Default is `30000` milliseconds.
- `ALFRESCO_DEPLOYMODEL_TIMEOUT` - The timeout (in milliseconds) for model deployment. Default is `960000` milliseconds.
