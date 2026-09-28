# Alfresco repository distribution

Place here the version of Alfresco Content Services distribution you want to
use in your Docker image.
Distribution file must be a ZIP file with the expected structure of an Alfresco
Content Services distribution.

> This folder is the default location for the `repo_distribution` build context.
> Override it with `--set repository.contexts.repo_distribution=<path>`.

```tree
keystore/
|_metadata-keystore/
bin/
licenses/
|_3rd-party/
web-server/
|_webapps/
|_shared/
  |_classes/
    |_alfresco/
|_conf/
  |_Catalina/
    |_localhost/
```
