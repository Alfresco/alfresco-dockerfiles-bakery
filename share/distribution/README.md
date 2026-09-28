# Alfresco Content Services share distribution

Place here the version of Alfresco Content Services share distribution you want to
use in your Docker image.
Distribution file must be a ZIP file with the expected structure of an Alfresco
Content Services share distribution.

> This folder is the default location for the `share_distribution` build context.
> Override it with `--set share.contexts.share_distribution=<path>`.

```tree
amps/
bin/
web-extension-samples/
web-server/
|_webapps/
|_conf/
  |_Catalina/
    |_localhost/
```
Do changes to `share-config-custom.xml` according to your needs.
