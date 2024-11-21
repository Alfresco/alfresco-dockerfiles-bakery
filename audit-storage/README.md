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

|  Variable   | Default |             Description                              |
|-------------|---------|------------------------------------------------------|
| `JAVA_OPTS` |    None | can be used to pass additionnal JRE options          |

### ActiveMQ configuration

|  Variable                   | Default |             Description               |
|-----------------------------|---------|---------------------------------------|
| `SPRING_ACTIVEMQ_BROKERURL` | `failover:(nio://localhost:61616)?timeout=3000` | URI of the ActiveMQ broker |
| `SPRING_ACTIVEMQ_USER`      |    None | ActiveMQ connection Username          |
| `SPRING_ACTIVEMQ_PASSWORD`  |    None | ActiveMQ connection Password          |

### Event ingestion configuration

|  Variable   | Default |             Description                              |
|-------------|---------|------------------------------------------------------|
| `AUDIT_EVENTINGESTION_PROCESSING_THREADS` | `8` | Number of threads used to process the events |
| `AUDIT_EVENTINGESTION_ERRORHANDLING_MAXIMUMREDELIVERIES` | `3` | Maximum number of delivery retries after a first failure |
| `AUDIT_EVENTINGESTION_ERRORHANDLING_REDELIVERYDELAY` | `5000` | Delay between two retries in milliseconds |
| `AUDIT_EVENTINGESTION_ERRORHANDLING_BACKOFFMULTIPLIER` | `2` | Multiplier used to increase the delay between two retries |
| `AUDIT_EVENTINGESTION_DLQ_URI` | `activemq:queue:audit.dlq?acknowledgementMode=4` | Dead Letter Queue URI for failed event processing |
| `AUDIT_EVENTINGESTION_DLQ_TIMER_URI` | `timer://dlqConsumerTrigger?delay=60000&fixedRate=true&period=1200000` | Timer URI to poll the DLQ |
| `AUDIT_EVENTINGESTION_DLQ_TIMER_CONSUMPTIONCOUNT` | `50` | Number of messages to consume from the Dead Letter Queue |
| `AUDIT_EVENTINGESTION_DLQ_TIMER_POLLENRICHTIMEOUT` | `500` | Timeout in milliseconds to poll the Dead Letter Queue |

### OpenSearch connector configuration

|  Variable   | Default |             Description                              |
|-------------|---------|------------------------------------------------------|
| `AUDIT_ENTRYSTORAGE_OPENSEARCH_CONNECTOR_INDEX` | `audit-event-index` | Audit entries index name |
| `AUDIT_ENTRYSTORAGE_OPENSEARCH_CONNECTOR_URI` | `http://localhost:9200` | URI of the OpenSearch/Elasticsearch cluster |
| `AUDIT_ENTRYSTORAGE_OPENSEARCH_CONNECTOR_USERNAME` | `admin` | Username to connect to the OpenSearch/Elasticsearch cluster |
| `AUDIT_ENTRYSTORAGE_OPENSEARCH_CONNECTOR_PASSWORD` | None | Password to connect to the OpenSearch/Elasticsearch cluster |

### Logging configuration

|  Variable                            | Default |         Description         |
|--------------------------------------|---------|-----------------------------|
| `LOGGING_LEVEL_ORG_ALFRESCO_PACKAGE` |   `INFO`| `org.alfresco.package` log level |

> Only works with packages not classes. For classes, consider using `JAVA_OPTS`.
