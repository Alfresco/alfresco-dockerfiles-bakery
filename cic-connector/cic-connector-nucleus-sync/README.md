# CIC Nucleus Sync

The CIC Nucleus Sync service synchronizes ACS repository metadata with Nucleus.

## Image

```yaml
alfresco-cic-connector-nucleus-sync:
  image: localhost/alfresco/alfresco-cic-connector-nucleus-sync:YOUR-TAG
```

## Runtime configuration

The Helm chart supplies the following configuration through its `cic`, `messageBroker`, `ats`, and `repository` values:

| Configuration | Description |
|---|---|
| `HX_AUTH_TOKEN_URL` | Hyland Experience OAuth token URL |
| `HX_INSIGHT_INGESTION_URL` | Hyland Experience ingestion URL |
| `HX_CLIENT_ID` / `HX_CLIENT_SECRET` | Hyland Experience client credentials |
| `HX_ENV_KEY` / `HX_APP_SOURCE_ID` | Hyland Experience environment and source identifiers |
| `NUCLEUS_BASE_URL` | Nucleus service URL |
| `NUCLEUS_IDP_BASE_URL` | Nucleus identity provider URL |
| `NUCLEUS_SYSTEM_ID` | Nucleus system identifier |
| `BROKER_URL` / `BROKER_USERNAME` / `BROKER_PASSWORD` | ActiveMQ connection |
| `REPOSITORY_URL` / `REPOSITORY_API_BASE_URL` | ACS repository endpoints |
| `REPOSITORY_VERSION_OVERRIDE` | ACS repository version used during startup |

## Health check

The image exposes port `8080` and checks:

```text
GET /actuator/health/readiness
```
