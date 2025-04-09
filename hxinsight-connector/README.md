# Runtime variables

Sets of variables configurable with your docker image

## Alfresco HxInsight component

```yaml

alfresco-hxinsight-connector:
    image: localhost/alfresco/alfresco-hxinsight-connector:YOUR-TAG
    environment:
      JAVA_OPTS:
      SPRING_ACTIVEMQ_BROKERURL:
      SPRING_ACTIVEMQ_USER:
      SPRING_ACTIVEMQ_PASSWORD:
      LOGGING_LEVEL_ORG_ALFRESCO_PACKAGE:
```

### Additional java options

|  Variable   | Default |             Description                             |
|-------------|---------|-----------------------------------------------------|
| `JAVA_OPTS` |    None | can be used to pass additional JRE options          |

### ActiveMQ configuration

| Variable                    | Default                                         | Description                  |
|-----------------------------|-------------------------------------------------|------------------------------|
| `SPRING_ACTIVEMQ_BROKERURL` | `failover:(nio://localhost:61616)?timeout=3000` | URI of the ActiveMQ broker   |
| `SPRING_ACTIVEMQ_USER`      | None                                            | ActiveMQ connection Username |
| `SPRING_ACTIVEMQ_PASSWORD`  | None                                            | ActiveMQ connection Password |

### Repository configuration

| Variable                                 | Default                  | Description                    |
|------------------------------------------|--------------------------|--------------------------------|
| `ALFRESCO_REPOSITORY_BASEURL`            | `http://127.0.0.1:8080/` | URI of the Alfresco repository |
| `ALFRESCO_REPOSITORY_RETRY_ATTEMPTS`     | None                     | Connection retry attempts      |
| `ALFRESCO_REPOSITORY_RETRY_INITIALDELAY` | None                     | Connection initial delay       |
| `AUTH_PROVIDERS_ALFRESCO_USERNAME`       | `admin`                  | Repository user name           |
| `AUTH_PROVIDERS_ALFRESCO_PASSWORD`       | `admin`                  | Repository user password       |

### Live Ingester configuration

| Variable                                         | Default | Description                                              |
|--------------------------------------------------|---------|----------------------------------------------------------|
| `HYLANDEXPERIENCE_INSIGHT_INGESTION_BASEURL`     | None    | Base URL for Insight Ingestion API of HxI environment    |
| `AUTH_PROVIDERS_HYLANDEXPERIENCE_CLIENTID`       | None    | Client Id of HxI environment                             |
| `AUTH_PROVIDERS_HYLANDEXPERIENCE_CLIENTSECRET`   | None    | Client secret of HxI environment                         |
| `AUTH_PROVIDERS_HYLANDEXPERIENCE_ENVIRONMENTKEY` | None    | HxI environment key                                      |
| `AUTH_PROVIDERS_HYLANDEXPERIENCE_TOKENURI`       | None    | URL for token of HxI environment                         |
| `AUTH_PROVIDERS_HYLANDEXPERIENCE_GRANTTYPE`      | None    | HxI grant type credentials                               |
| `APPLICATION_SOURCEID`                           | None    | UUID identifying which systems can use this agent        |
| `ALFRESCO_FILTER_ASPECT_ALLOW`                   | None    | Allow lists to filter the aspects sent to Hyland Insight |
| `ALFRESCO_FILTER_ASPECT_DENY`                    | None    | Deny lists to filter the aspects sent to Hyland Insight  |
| `ALFRESCO_FILTER_TYPE_ALLOW`                     | None    | Allow lists to filter the types sent to Hyland Insight   |
| `ALFRESCO_FILTER_TYPE_DENY`                      | None    | Deny lists to filter the types sent to Hyland Insight    |
| `ALFRESCO_FILTER_PATH_ALLOW`                     | None    | Allow lists to filter the paths sent to Hyland Insight   |
| `ALFRESCO_FILTER_PATH_DENY`                      | None    | Deny lists to filter the paths sent to Hyland Insight    |

Allow and deny lists to filter the nodes sent to Hyland Insight.  
Any node with an aspect/type/ancestor matching something in each “allow” list will be sent to Insight unless it also matches something in a “deny” list.  
An empty “allow” list is treated as matching all nodes.

### Prediction Applier configuration

| Variable                                         | Default | Description                                       |
|--------------------------------------------------|---------|---------------------------------------------------|
| `HYLANDEXPERIENCE_INSIGHT_PREDICTIONS_BASEURL`   | None    | Base URL for Prediction API of HxI environment    |
| `AUTH_PROVIDERS_HYLANDEXPERIENCE_CLIENTID`       | None    | Client Id of HxI environment                      |
| `AUTH_PROVIDERS_HYLANDEXPERIENCE_CLIENTSECRET`   | None    | Client secret of HxI environment                  |
| `AUTH_PROVIDERS_HYLANDEXPERIENCE_ENVIRONMENTKEY` | None    | HxI environment key                               |
| `AUTH_PROVIDERS_HYLANDEXPERIENCE_TOKENURI`       | None    | URL for token of HxI environment                  |
| `AUTH_PROVIDERS_HYLANDEXPERIENCE_GRANTTYPE`      | None    | HxI grant type credentials                        |
| `APPLICATION_SOURCEID`                           | None    | UUID identifying which systems can use this agent |

### Logging configuration

| Variable                     | Default | Description              |
|------------------------------|---------|--------------------------|
| `LOGGING_LEVEL_ORG_ALFRESCO` | `INFO`  | `org.alfresco` log level |

> Only works with packages not classes. For classes, consider using `JAVA_OPTS`.
