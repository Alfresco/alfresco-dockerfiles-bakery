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
docker buildx bake search_batch_indexing
```

To build for a specific ACS version (default is 26):

```bash
ACS_VERSION=25 docker buildx bake search_batch_indexing
```

## Runtime variables

The following environment variables can be passed at container start-up to
configure the batch indexer:

| Variable | Description | Default |
|---|---|---|
| `JAVA_OPTS` | Additional JVM options (heap, GC, etc.) | _(empty)_ |
| `SPRING_ELASTICSEARCH_REST_URIS` | Comma-separated list of Elasticsearch REST endpoints | `http://elasticsearch:9200` |
| `SPRING_ACTIVEMQ_BROKERURL` | ActiveMQ broker URL | `nio://activemq:61616` |
| `ALFRESCO_ACCEPTED_CONTENT_MEDIA_TYPES_CACHE_ENABLED` | Enable/disable media-types cache | `true` |

Example Docker Compose snippet:

```yaml
batch-indexer:
  image: localhost/alfresco/alfresco-elasticsearch-batch-indexing:latest
  environment:
    SPRING_ELASTICSEARCH_REST_URIS: http://elasticsearch:9200
    SPRING_ACTIVEMQ_BROKERURL: nio://activemq:61616
```

## Customizing the image

The batch indexing image can be customized by extending it or by bind-mounting
configuration files. The Spring Boot application reads its configuration from
the standard Spring externalized configuration locations, so you can override
any property by:

1. **Environment variables** — set `SPRING_*` or `ALFRESCO_*` env vars.
2. **Mounted config file** — mount a custom `application.properties` or
   `application.yaml` to `/opt/app-config/`.

## Artifacts

The artifact fetched for this component is:

| Artifact | Repository | Group |
|---|---|---|
| `alfresco-elasticsearch-batch-indexing-<version>-app.jar` | `releases` | `org.alfresco` |

Version mappings per ACS line are defined in the `artifacts-*.yaml` files in
this directory and are kept up to date by the `updatecli` pipeline.

## Helm chart

This image is deployed by the `alfresco-search-community` Helm chart, which is
the community counterpart to the enterprise `alfresco-search-enterprise` chart.
The chart image reference key is `alfresco-search-community.image.repository`.
