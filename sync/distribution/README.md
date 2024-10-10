# Alfresco Sync Service distribution

Place here the version of Alfresco Sync Service distribution you want to use in
your Docker image. Distribution file must be a ZIP file with the expected
structure of an Alfresco Sync Service distribution. Only the contents of the
`sync/service-sync/` will be copied by default.

```tree
sync/
|_service-sync/
  syncservice.sh
  sync.p12
  config.yml
  service-sync-x.x.x.jar
```
