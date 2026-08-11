# Alfresco Content Repository Simple Module (JAR)

You can read the full documentation about Simple Module in the [Alfresco
documentation](https://docs.hyland.com/search/all?query=simple+module+jars&value-filters=platform_custom~%2522Alfresco%2522&content-lang=en-US).

This folder is the default content of the `repo_simple_modules` build context.
To add Simple Modules produced by the [Alfresco
SDK](https://github.com/Alfresco/alfresco-sdk) to every built repository image,
repoint `repo_simple_modules` at a directory of your own rather than adding
files here, which would require a fork of this repository. See [customizing the
image](../README.md#customizing-the-image). A context you repoint replaces this
folder entirely.
