# Alfresco share AMPs

Place here your Alfresco module Packages (AMPs) to be installed in the Alfresco
share.

AMP packages should have the `.amp` extension and stick to the Alfresco module
packaging format as described in the [Alfresco documentation][amp].

The [in-process Alfresco SDK][sdk] provides a way to build well structured AMPs.

> Note that AMPs are not the recommanded way to extend Alfresco. You should
> prefer using the Alfresco SDK to build your extensions as JARs even better,
> use the [out-of-process Alfresco SDK][oop] to
> build Docker images with your extensions.

By default the `scripts/fetch-artifacts.py` script will fetch the following AMPs from the Alfresco Nexus repository:

* alfresco-googledrive-share

You can replace those, remove them to keep only the ones you need or add more.

[sdk]: https://support.hyland.com/r/Alfresco/Alfresco-In-Process-SDK/4.10/Alfresco-In-Process-SDK/Introduction
[oop]: https://support.hyland.com/r/Alfresco/Alfresco-Content-Services/23.4/Alfresco-Content-Services/Develop/Out-of-Process-Extension-Points/Events-Extension-Point
[amp]: https://support.hyland.com/r/Alfresco/Alfresco-Content-Services/23.4/Alfresco-Content-Services/Develop/Extension-Packaging-Modules/Module-Package-Formats/Alfresco-Module-Package-AMP
