# Runtime variables

Sets of variables configurable with your docker image

## Alfresco repository Audit component

```yaml

alfresco-audit-storage:
    image: localhost/alfresco-audit-storage:YOUR-TAG
    environment:
      JAVA_OPTS:
      SPRING_ACTIVEMQ_BROKERURL:
      SPRING_ACTIVEMQ_USER:
      SPRING_ACTIVEMQ_PASSWORD:
      AUDIT_EVENTINGESTION_PROCESSING_THREADS:
      AUDIT_EVENTINGESTION_ERRORHANDLING_MAXIMUMREDELIVERIES:
      AUDIT_EVENTINGESTION_ERRORHANDLING_REDELIVERYDELAY:
      AUDIT_EVENTINGESTION_ERRORHANDLING_BACKOFFMULTIPLIER:
      AUDIT_EVENTINGESTION_DLQ_URI:
      AUDIT_EVENTINGESTION_DLQ_TIMER_URI:
      AUDIT_EVENTINGESTION_DLQ_TIMER_CONSUMPTIONCOUNT:
      AUDIT_EVENTINGESTION_DLQ_TIMER_POLLENRICHTIMEOUT:
      AUDIT_ENTRYSTORAGE_OPENSEARCH_CONNECTOR_INDEX:
      AUDIT_ENTRYSTORAGE_OPENSEARCH_CONNECTOR_URI:
      AUDIT_ENTRYSTORAGE_OPENSEARCH_CONNECTOR_USERNAME:
      AUDIT_ENTRYSTORAGE_OPENSEARCH_CONNECTOR_PASSWORD:
      LOGGING_LEVEL_ORG_ALFRESCO_PACKAGE:
```

### Additional java options

`JAVA_OPTS` can be used to pass additionnal JRE options

> Default: None

### ActiveMQ configuration

`SPRING_ACTIVEMQ_BROKERURL` is the URL of the ActiveMQ broker

> Default: failover:(nio://localhost:61616)?timeout=3000

`SPRING_ACTIVEMQ_USER` is the username to connect to the ActiveMQ broker

> Default: None

`SPRING_ACTIVEMQ_PASSWORD` is the password to connect to the ActiveMQ broker

> Default: None

### Event ingestion configuration

`AUDIT_EVENTINGESTION_PROCESSING_THREADS` is the number of threads used to
process the events

> Default: 8

`AUDIT_EVENTINGESTION_ERRORHANDLING_MAXIMUMREDELIVERIES` is the maximum number
of delivery retries after a first failure

> Default: 3

`AUDIT_EVENTINGESTION_ERRORHANDLING_REDELIVERYDELAY` is the delay between two
retries in milliseconds

> Default: 5000

`AUDIT_EVENTINGESTION_ERRORHANDLING_BACKOFFMULTIPLIER` is the multiplier used to
increase the delay between two retries

> Default: 2

`AUDIT_EVENTINGESTION_DLQ_URI` is the URI of the Dead Letter Queue where failed
event processing are stored

> Default: activemq:queue:audit.dlq?acknowledgementMode=4

`AUDIT_EVENTINGESTION_DLQ_TIMER_URI` is the URI of the timer used to poll the
Dead Letter Queue

> Default: timer://dlqConsumerTrigger?delay=60000&fixedRate=true&period=1200000

`AUDIT_EVENTINGESTION_DLQ_TIMER_CONSUMPTIONCOUNT` is the number of messages to
consume from the Dead Letter Queue

> Default: 50

`AUDIT_EVENTINGESTION_DLQ_TIMER_POLLENRICHTIMEOUT` is the timeout in
milliseconds to poll the Dead Letter Queue

> Default: 500

### OpenSearch connector configuration

`AUDIT_ENTRYSTORAGE_OPENSEARCH_CONNECTOR_INDEX` is the name of index used to
store the audit entries

> Default: audit-event-index

`AUDIT_ENTRYSTORAGE_OPENSEARCH_CONNECTOR_URI` is the URI of the
OpenSearch/Elasticsearch cluster

> Default: http://localhost:9200

`AUDIT_ENTRYSTORAGE_OPENSEARCH_CONNECTOR_USERNAME` is the username to connect to
the OpenSearch/Elasticsearch cluster

> Default: admin

`AUDIT_ENTRYSTORAGE_OPENSEARCH_CONNECTOR_PASSWORD` is the password to connect to
the OpenSearch/Elasticsearch cluster

> Default: admin

### Logging configuration

`LOGGING_LEVEL_ORG_ALFRESCO_PACKAGE` is the log level for the
`org.alfresco.package.name` package (only package name without the class name)
