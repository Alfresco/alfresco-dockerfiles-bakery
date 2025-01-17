# Alfresco Content Repository Simple Module (JAR)

Full documentation on Simple Module is here:
https://support.hyland.com/r/Alfresco/Alfresco-Content-Services/23.4/Alfresco-Content-Services/Develop/Extension-Packaging-Modules/Module-Package-Formats/Alfresco-Module-Package-AMP/Using-the-Module-Management-Tool-MMT/Simple-Module-JAR

To add Simple Module with alfresco-dockerfiles-bakery:

1. Copy jar files produced by the [Alfresco SDK](https://github.com/Alfresco/alfresco-sdk) into `repository/simple_modules/jars`

2. If your module consists configuration files such as `module.properties` copy
   them into `repository/simple_modules/config/properties/<your_module_name>`.
   Replace `<your_module_name>` with the name of the module you're installing.
   This ensures proper organization and avoids conflicts.

3. Use similar approach if your module have any web resources. Copy them into
   `repository/simple_modules/config/resources/<your_module_name>`.

Below is an example of how a module named
`alfresco-hxinsight-connector-hxinsight-extension` should be structured:

```tree
simple_modules
├── config
│   ├── properties
│   │   └── alfresco-hxinsight-connector-hxinsight-extension
│   │       └── module.properties
│   └── resources
└── jars
    └── alfresco-hxinsight-connector-hxinsight-extension-1.0.1.jar
```

In this example, the `module.properties` file is optional. It’s included here to
illustrate how configuration files can be structured for proper integration.
Organizing your configuration files and resources this way ensures that they are
correctly packaged into the Docker image.
