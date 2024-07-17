# Runtime variables

Sets of variables configurable with your docker image

## metadata

```yaml

live-indexing-metadata:
    image: alfresco-enterprise-search-metadata:YOUR-TAG
    environment:
        SPRING_ELASTICSEARCH_REST_URIS: http://elasticsearch:9200
        SPRING_ACTIVEMQ_BROKERURL: nio://activemq:61616

```

- `SPRING_ELASTICSEARCH_REST_URIS` - Elasticsearch server, by default `http://elasticsearch:9200`
- `SPRING_ACTIVEMQ_BROKERURL` - Alfresco ActiveMQ, by default `nio://activemq:61616`

## path

```yaml

live-indexing-path:
    image: alfresco-enterprise-search-path:YOUR-TAG
    environment:
        SPRING_ELASTICSEARCH_REST_URIS: http://elasticsearch:9200
        SPRING_ACTIVEMQ_BROKERURL: nio://activemq:61616

```

- `SPRING_ELASTICSEARCH_REST_URIS` - Elasticsearch server, by default `http://elasticsearch:9200`
- `SPRING_ACTIVEMQ_BROKERURL` - Alfresco ActiveMQ, by default `nio://activemq:61616`
