# CIC Bulk Ingester

The CIC Bulk Ingester performs the initial content crawl and publishes ingestion events through ActiveMQ.

## Image

```yaml
alfresco-cic-connector-bulk-ingester:
  image: localhost/alfresco/alfresco-cic-connector-bulk-ingester:YOUR-TAG
```

## Runtime configuration

The Helm chart supplies the following configuration through its `cic`, `messageBroker`, `ats`, and `repository` values:

| Configuration | Description |
|---|---|
| `HX_AUTH_TOKEN_URL` | Hyland Experience OAuth token URL |
| `HX_INSIGHT_INGESTION_URL` | Hyland Experience ingestion URL |
| `HX_CLIENT_ID` / `HX_CLIENT_SECRET` | Hyland Experience client credentials |
| `HX_ENV_KEY` / `HX_APP_SOURCE_ID` | Hyland Experience environment and source identifiers |
| `BROKER_URL` / `BROKER_USERNAME` / `BROKER_PASSWORD` | ActiveMQ connection |
| `SFS_URL` | Shared File Store URL |
| `REPOSITORY_URL` / `REPOSITORY_API_BASE_URL` | ACS repository endpoints |
| `REPOSITORY_VERSION_OVERRIDE` | ACS repository version used during startup |

## Container configuration

- Port: `8080`
- Startup command: `java $JAVA_OPTS -jar /opt/app.jar`

The Helm chart runs the Bulk Ingester as a Kubernetes Job. It waits for the ACS repository readiness endpoint before starting the initial crawl; Job completion is the Kubernetes test signal.

The image also defines this container health check:

```text
GET /actuator/health/readiness
```
