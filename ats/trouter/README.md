# Runtime variables

Sets of variables configurable with your docker image

## trouter

```yaml

transform-router:
    image: alfresco-transform-router:YOUR-TAG
    environment:
      JAVA_OPTS: >-
        -XX:MinRAMPercentage=50
        -XX:MaxRAMPercentage=80
      ACTIVEMQ_URL: nio://activemq:61616
      CORE_AIO_URL: http://transform-core-aio:8090
      FILE_STORE_URL: http://shared-file-store:8099/alfresco/api/-default-/private/sfs/versions/1/file

```
- `JAVA_OPTS` - Additional java options
- `CORE_AIO_URL` - Transform Core AIO server
- `ACTIVEMQ_URL` - Alfresco ActiveMQ
- `FILE_STORE_URL` - Alfresco Shared FileStore endpoint
