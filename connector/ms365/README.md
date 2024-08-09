# Runtime variables

Sets of variables configurable with your docker image

## msteams

```yaml

alfresco-connector-msteams:
    image: localhost/alfresco-ooi-service:YOUR-TAG
    environment:
      JAVA_OPTS: "-Dalfresco.base-url=http://alfresco:8080"
        
```

- `JAVA_OPTS` - Additional java options
