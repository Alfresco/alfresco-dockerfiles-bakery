# Runtime variables

Sets of variables configurable with your docker image

## -pdf-renderer

```yaml

transform-core-pdf-renderer:
    image: localhost/alfresco-pdf-renderer:YOUR-TAG
    environment:
      JAVA_OPTS:
      ACTIVEMQ_URL: nio://activemq:61616
      ACTIVEMQ_USER: admin
      ACTIVEMQ_PASSWORD: admin
      FILE_STORE_URL: http://shared-file-store:8099/alfresco/api/-default-/private/sfs/versions/1/file

```

- `JAVA_OPTS` - Additional java options
- `ACTIVEMQ_URL` - The URL for Alfresco ActiveMQ.
- `FILE_STORE_URL` -  Alfresco Shared FileStore endpoint.
