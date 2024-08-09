# Runtime variables

Sets of variables configurable with your docker image

## msteams

```yaml

alfresco-connector-msteams:
    image: localhost/alfresco-ms-teams-service:YOUR-TAG
    environment:
      JAVA_OPTS:
      ALFRESCO_BASE_URL:  
      ALFRESCO_DIGITAL_WORKSPACE_CONTEXT_PATH:
      MICROSOFT_APP_OAUTH_CONNECTION_NAME:
      MICROSOFT_APP_ID:
      MICROSOFT_APP_PASSWORD:
      TEAMS_CHAT_FILENAME_ENABLED: 
      TEAMS_CHAT_METADATA_ENABLED:
      TEAMS_CHAT_IMAGE_ENABLED: 
```

- `JAVA_OPTS` - Additional java options
- `ACS_BASE_URL` - The base URL of the Content Services installation in the format `<domain>:<port>`. For example, {my.domain}/
- `ALFRESCO_DIGITAL_WORKSPACE_CONTEXT_PATH` - The Alfresco Digital Workspace context path in the Content Services installation, usually /workspace
- `MICROSOFT_APP_OAUTH_CONNECTION_NAME` - OAuth Connection name
- `MICROSOFT_APP_ID` -  The Azure Bot application identifier created when registering the Azure bot and looks something like `9af7ae3a-1798-4de7-a992-c3ac48****`
- `MICROSOFT_APP_PASSWORD` - The Azure Bot application password
- `TEAMS_CHAT_FILENAME_ENABLED` - Enables or disables the inclusion of filenames in Teams chat messages. Set to `true` to include filenames, or `false` to exclude them.
- `TEAMS_CHAT_METADATA_ENABLED` - Enables or disables the inclusion of metadata in Teams chat messages. Set to `true` to include metadata, or `false` to exclude it.
- `TEAMS_CHAT_IMAGE_ENABLED` - Enables or disables the inclusion of images in Teams chat messages. Set to `true` to include images, or `false` to exclude them.
