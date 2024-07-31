# Runtime variables

Sets of variables configurable with your docker image

## tika

```yaml

transform-core-tika:
    image: localhost/alfresco-tika:YOUR-TAG
    environment:
      JAVA_OPTS: 
      ACTIVEMQ_URL: nio://activemq:61616
      FILE_STORE_URL: http://shared-file-store:8099/alfresco/api/-default-/private/sfs/versions/1/file

```

- `JAVA_OPTS` - Additional java options
- `ACTIVEMQ_URL` - The URL for Alfresco ActiveMQ.
- `FILE_STORE_URL` -  Alfresco Shared FileStore endpoint.
