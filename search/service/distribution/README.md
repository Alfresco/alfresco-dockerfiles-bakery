# Alfresco Search service distribution

Place here the version of Alfresco Content Services distribution you want to
use in your Docker image.
Distribution file must be a ZIP file with the expected structure of an Alfresco
Search Services distribution.

```tree
alfresco-search-services
├── licenses
│   ├── 3rd-party
│   └── solr
├── logs
├── solr
│   ├── bin
│   │   └── init.d
│   ├── docs
│   │   └── images
│   ├── licenses
│   └── server
│       ├── contexts
│       ├── etc
│       ├── lib
│       │   └── ext
│       ├── modules
│       ├── resources
│       ├── scripts
│       │   └── cloud-scripts
│       └── solr-webapp
│           └── webapp
│               ├── WEB-INF
│               │   └── lib
│               ├── css
│               │   └── angular
│               ├── img
│               │   ├── filetypes
│               │   └── ico
│               ├── js
│               │   ├── angular
│               │   │   └── controllers
│               │   └── lib
│               ├── libs
│               └── partials
└── solrhome
    ├── alfrescoModels
    ├── conf
    └── templates
        ├── noRerank
        │   └── conf
        │       └── lang
        └── rerank
            └── conf
                └── lang
```
