# Alfresco Elasticsearch Community Batch Indexing image

## Description

This Dockerfile builds an Alfresco Elasticsearch Community Batch Indexing
image. The batch indexer is a Spring Boot application that indexes content from
an Alfresco Content Repository into an Elasticsearch cluster using a batch
(non-real-time) approach. It is the community counterpart to the enterprise live
indexing / reindexing components.

## Building the image

Make sure all required artifacts are present in the build context
`search/community/`. Use the script `./scripts/fetch_artifacts.py` to download
them from Alfresco's Nexus:

```bash
python3 ./scripts/fetch_artifacts.py search/community
```

or via the Makefile convenience target:

```bash
make prepare_search_community
```

Then build the image from the root of this repository:

```bash
ACS_VERSION=26 docker buildx bake search_batch_indexing
```

## Runtime variables

The following environment variables can be passed at container start-up to
configure the batch indexer:

| Variable | Description | Default |
|---|---|---|
| `JAVA_OPTS` | Additional JVM options (heap, GC, etc.) | _(empty)_ |
| `SPRING_DATASOURCE_URL` | JDBC URL for the Alfresco database | _(empty)_ |
| `SPRING_DATASOURCE_USERNAME` | Alfresco database username | _(empty)_ |
| `SPRING_DATASOURCE_PASSWORD` | Alfresco database password | _(empty)_ |
| `SPRING_ELASTICSEARCH_REST_URIS` | Comma-separated list of Elasticsearch REST endpoints | `http://elasticsearch:9200` |
| `ALFRESCO_ACCEPTEDCONTENTMEDIATYPESCACHE_BASEURL` | ATS endpoint used to retrieve accepted content media types | _(empty)_ |
| `ALFRESCO_ACCEPTEDCONTENTMEDIATYPESCACHE_ENABLED` | Enable or disable the accepted content media types cache. Set to `true` when using ATS AIO; leave it `false` when using specialized transform engines. | `false` |
| `ALFRESCO_ACS_URL` | Alfresco Content Repository URL | _(empty)_ |
| `ALFRESCO_CONTENT_TRANSFORM_SHAREDSECRET` | Shared secret used for content transformation communication | _(empty)_ |
| `ALFRESCO_REINDEX_CONTINUOUS_POLLINGINTERVAL` | Interval between continuous reindexing polls | _(empty)_ |
| `ALFRESCO_REINDEX_CONTINUOUS_CATCHUPPOLLINGINTERVAL` | Interval between catch-up polls | _(empty)_ |
| `ALFRESCO_REINDEX_CONTINUOUS_MAXWINDOW` | Maximum continuous reindexing window | _(empty)_ |
| `ALFRESCO_REINDEX_CONTINUOUS_OVERLAP` | Overlap between continuous reindexing windows | _(empty)_ |

Example Docker Compose snippet:

```yaml
batch-indexer:
  image: localhost/alfresco/alfresco-elasticsearch-batch-indexing:latest
  environment:
    JAVA_OPTS: -Xms256m -Xmx768m
    SPRING_DATASOURCE_URL: jdbc:postgresql://postgres:5432/alfresco
    SPRING_DATASOURCE_USERNAME: alfresco
    SPRING_DATASOURCE_PASSWORD: alfresco
    SPRING_ELASTICSEARCH_REST_URIS: http://elasticsearch:9200
    ALFRESCO_ACCEPTEDCONTENTMEDIATYPESCACHE_BASEURL: http://transform-core-aio:8090/transform/config
    ALFRESCO_ACS_URL: http://alfresco:8080
    ALFRESCO_CONTENT_TRANSFORM_SHAREDSECRET: secret
    ALFRESCO_REINDEX_CONTINUOUS_POLLINGINTERVAL: 15s
    ALFRESCO_REINDEX_CONTINUOUS_CATCHUPPOLLINGINTERVAL: 1s
    ALFRESCO_REINDEX_CONTINUOUS_MAXWINDOW: 30m
    ALFRESCO_REINDEX_CONTINUOUS_OVERLAP: 10m
```

## Artifacts

The artifact fetched for this component is:

| Artifact | Repository | Group |
|---|---|---|
| `alfresco-elasticsearch-batch-indexing-<version>-app.jar` | `releases` | `org.alfresco` |

This component only supports **ACS 26.2 and later**. A single `artifacts-26.yaml`
file defines the artifact version and is kept up to date by the `updatecli` pipeline.

## Helm chart

This image is deployed by the `alfresco-search-community` Helm chart, which is
the community counterpart to the enterprise `alfresco-search-enterprise` chart.
The chart image reference key is `alfresco-search-community.image.repository`.
