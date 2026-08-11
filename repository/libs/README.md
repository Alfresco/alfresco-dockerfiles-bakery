# Alfresco Content Repository extra jars

This folder is the default content of the `repo_libs` build context: jar files
deployed in the Tomcat lib directory, which is a suitable way to add JDBC
drivers.

To ship jars of your own, repoint `repo_libs` at a directory of your own rather
than adding files here, which would require a fork of this repository. See
[customizing the image](../README.md#customizing-the-image). A context you
repoint replaces this folder entirely, so your directory must also hold the
JDBC driver shipped here if you still need it.
