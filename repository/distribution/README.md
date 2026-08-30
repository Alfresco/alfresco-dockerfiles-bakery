# Alfresco repository distribution

This folder is the default content of the `repo_distribution` build context: the
Alfresco Content Services distribution the image is built from.
`scripts/fetch_artifacts.py` populates it from the `artifacts-NN.yaml` file of
the version you are building.

To build from a distribution of your own, repoint `repo_distribution` at a
directory of your own rather than adding files here, which would require a fork
of this repository. See [customizing the
image](../README.md#customizing-the-image).

The distribution must be a ZIP file with the expected structure of an Alfresco
Content Services distribution.

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
