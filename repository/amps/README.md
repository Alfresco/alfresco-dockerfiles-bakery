# Alfresco repository AMPs

This folder is the default content of the `repo_amps` build context: the
Alfresco Module Packages (AMPs) installed in the repository image for both
editions.

To ship AMPs of your own, repoint `repo_amps` at a directory of your own rather
than adding files here, which would require a fork of this repository. See
[customizing the image](../README.md#customizing-the-image).

AMP packages should have the `.amp` extension and stick to the Alfresco module
packaging format as described in the [Alfresco documentation][amp].

The [in-process Alfresco SDK][sdk] provides a way to build well structured AMPs.

> Note that AMPs are not the recommanded way to extend Alfresco. You should
> prefer using the Alfresco SDK to build your extensions as JARs even better,
> use the [out-of-process Alfresco SDK][oop] to
> build Docker images with your extensions.

By default the `scripts/fetch_artifacts.py` script will fetch some default AMPs,
see the `artifacts-NN.yaml` for the version you are building for further
details.

A context you repoint replaces this folder entirely, so your directory must also
hold the AMPs from `artifacts-NN.yaml` you still want installed. Be careful as
some AMPs may depend on one another (e.g. `googledrive-repo` depends on
`alfresco-share-services`).

[sdk]: https://docs.hyland.com/r/Alfresco/Alfresco-In-Process-SDK/4.10/Alfresco-In-Process-SDK/Introduction
[oop]: https://docs.hyland.com/r/Alfresco/Alfresco-Content-Services/26.1/Alfresco-Content-Services/Develop/Out-of-Process-Extension-Points/Events-Extension-Point
[amp]: https://docs.hyland.com/r/Alfresco/Alfresco-Content-Services/26.1/Alfresco-Content-Services/Develop/Extension-Packaging-Modules/Module-Package-Formats/Alfresco-Module-Package-AMP
