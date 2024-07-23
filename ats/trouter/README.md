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
- `CORE_AIO_URL` - Transform Core AIO server, by default `http://elasticsearch:9200`
- `ACTIVEMQ_URL` - Alfresco ActiveMQ, by default `nio://activemq:61616`
- `FILE_STORE_URL` - Alfresco Shared FileStore endpoint, by default `http://shared-file-store:8099/alfresco/api/-default-/private/sfs/versions/1/file/`

## path

```yaml

live-indexing-path:
    image: alfresco-elasticsearch-live-indexing-path:YOUR-TAG
    environment:
        SPRING_ELASTICSEARCH_REST_URIS: http://elasticsearch:9200
        SPRING_ACTIVEMQ_BROKERURL: nio://activemq:61616

```

- `SPRING_ELASTICSEARCH_REST_URIS` - Elasticsearch server, by default `http://elasticsearch:9200`
- `SPRING_ACTIVEMQ_BROKERURL` - Alfresco ActiveMQ, by default `nio://activemq:61616`

## content

```yaml

live-indexing-content:
    image: alfresco-elasticsearch-live-indexing-content:YOUR-TAG
    environment:
        SPRING_ELASTICSEARCH_REST_URIS: http://elasticsearch:9200
        SPRING_ACTIVEMQ_BROKERURL: nio://activemq:61616
        ALFRESCO_SHAREDFILESTORE_BASEURL: http://shared-file-store:8099/alfresco/api/-default-/private/sfs/versions/1/file

```

- `SPRING_ELASTICSEARCH_REST_URIS` - Elasticsearch server, by default `http://elasticsearch:9200`
- `SPRING_ACTIVEMQ_BROKERURL` - Alfresco ActiveMQ, by default `nio://activemq:61616`
- `ALFRESCO_SHAREDFILESTORE_BASEURL` - Alfresco Shared FileStore endpoint, by default `http://shared-file-store:8099/alfresco/api/-default-/private/sfs/versions/1/file/`

## all-in-one

```yaml

live-indexing:
    image: alfresco-enterprise-search-aio:YOUR-TAG
    environment:
        SPRING_ELASTICSEARCH_REST_URIS: http://elasticsearch:9200
        SPRING_ACTIVEMQ_BROKERURL: nio://activemq:61616
        ALFRESCO_SHAREDFILESTORE_BASEURL: http://shared-file-store:8099/alfresco/api/-default-/private/sfs/versions/1/file/

```
