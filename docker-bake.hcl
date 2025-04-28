group "default" {
  targets = ["enterprise", "community"]
}

group "enterprise" {
  targets = [
    "content_service_enterprise",
    "search_enterprise",
    "ats",
    "tengines",
    "connectors",
    "adf_apps",
    "sync",
    "content_service_enterprise_from_25"
  ]
}

group "community" {
  targets = ["content_service_community", "search_service", "tengines", "acc"]
}

group "content_service_enterprise" {
  targets = exclude_if_version(
    ["74", "73"],
    [
      "repository_enterprise",
      "share_enterprise",
      "audit_storage"
    ],
    [
      "audit_storage"
    ]
  )
}
group "content_service_enterprise_from_25" {
  targets = exclude_if_version(
    ["23", "74", "73"],
    [
      "hxinsight_connector_live_ingester",
    ],
    [
      "hxinsight_connector_live_ingester"
    ]
  )
}

group "content_service_community" {
  targets = ["repository_community", "share_community"]
}

group "search_enterprise" {
  targets = ["search_liveindexing", "search_reindexing"]
}

group "ats" {
  targets = ["ats_trouter", "ats_sfs"]
}

group "tengines" {
  targets = ["tengine_libreoffice", "tengine_imagemagick", "tengine_tika", "tengine_pdfrenderer", "tengine_misc", "tengine_aio"]
}

group "connectors" {
  targets = ["connector_msteams", "connector_ms365"]
}

group "adf_apps" {
  targets = ["acc", "adw"]
}

variable "REGISTRY" {
  default = "localhost"
}

variable "REGISTRY_NAMESPACE" {
  default = "alfresco"
}

variable "TARGETARCH" {
  default = ""
}

variable "TAG" {
  default = "latest"
}

variable "LABEL_VENDOR" {
  default = "Hyland Software, Inc."
}

variable "LABEL_AUTHOR" {
  default = "Alfresco OPS-Readiness"
}

variable "LABEL_SOURCE" {
  default = "https://github.com/Alfresco/alfresco-dockerfiles-bakery"
}

variable "LABEL_GIT_SOURCE" {
  default = "${LABEL_SOURCE}.git"
}

variable "PRODUCT_LINE" {
  default = "Alfresco"
}

variable "CREATED" {
  default = formatdate("YYYY'-'MM'-'DD'T'hh':'mm':'ss'Z'", timestamp())
}

variable "GITHUB_SHA" {
  default = "deadbeef"
}

variable "REVISION" {
  default = "${GITHUB_SHA}"
}

variable "DISTRIB_NAME" {
  default = "rockylinux"
}

variable "DISTRIB_MAJOR" {
  default = "9"
}

variable "JDIST" {
  default = "jre"
}

variable "IMAGE_BASE_LOCATION" {
  default = "docker.io/rockylinux:9"
}

variable "JAVA_MAJOR" {
  default = "17"
}

variable "LIVEINDEXING" {
  default = "metadata"
}

variable "ALFRESCO_GROUP_ID" {
  default = "1000"
}

variable "ALFRESCO_GROUP_NAME" {
  default = "alfresco"
}

variable "ACS_VERSION" {
}

function "exclude_if_version" {
  params = [
    versions,  # list of string versions
    inputlist, # list of string targets
    excludees  # list of string targets to exclude
    ]
  result = sethaselement(versions,"${ACS_VERSION}") ? setsubtract(inputlist, excludees) : inputlist
}

target "java_base" {
  context = "./java"
  dockerfile = "Dockerfile"
  args = {
    DISTRIB_NAME = "${DISTRIB_NAME}"
    DISTRIB_MAJOR = "${DISTRIB_MAJOR}"
    JDIST = "${JDIST}"
    IMAGE_BASE_LOCATION = "${IMAGE_BASE_LOCATION}"
    JAVA_MAJOR = "${JAVA_MAJOR}"
  }
  labels = {
    "org.label-schema.schema-version" = "1.0"
    "org.label-schema.name" = "${PRODUCT_LINE} Java"
    "org.label-schema.vendor" = "${LABEL_VENDOR}"
    "org.label-schema.build-date" = "${CREATED}"
    "org.label-schema.url" = "${LABEL_SOURCE}"
    "org.label-schema.vcs-url" = "${LABEL_GIT_SOURCE}"
    "org.label-schema.vcs-ref" = "${REVISION}"
    "org.opencontainers.image.title" = "${PRODUCT_LINE} Java"
    "org.opencontainers.image.description" = "A base image shipping OpenJDK JRE ${JAVA_MAJOR} for Alfresco Products"
    "org.opencontainers.image.vendor" = "${LABEL_VENDOR}"
    "org.opencontainers.image.created" = "${CREATED}"
    "org.opencontainers.image.revision" = "${REVISION}"
    "org.opencontainers.image.url" = "${LABEL_SOURCE}"
    "org.opencontainers.image.source" = "${LABEL_GIT_SOURCE}"
    "org.opencontainers.image.authors" = "${LABEL_AUTHOR}"
  }
  tags = ["${REGISTRY}/${REGISTRY_NAMESPACE}/alfresco-base-java:${JDIST}${JAVA_MAJOR}-${DISTRIB_NAME}${DISTRIB_MAJOR}"]
  output = ["type=cacheonly"]
  platforms = split(",", "${TARGETARCH}")
}

# Tomcat variables are set by makefile using tomcat/tomcat_versions.yaml
variable "TOMCAT_MAJOR" {}
variable "TOMCAT_VERSION" {}
variable "TOMCAT_SHA512" {}

variable "TCNATIVE_VERSION" {
  default = "2.0.8"
}

variable "TCNATIVE_SHA512" {
  default = "fd45533b9c34b008717d18ed49334c7286b93c849c487c1c42746f2998cc4a6ff0362e536a8b5124c6539847a92a9f7631c7638a21cd5d22134fe1a9bb0f0702"
}

target "tomcat_base" {
  context = "./tomcat"
  dockerfile = "Dockerfile"
  inherits = ["java_base"]
  contexts = {
    java_base = "target:java_base"
  }
  args = {
    TOMCAT_MAJOR = "${TOMCAT_MAJOR}"
    TOMCAT_VERSION = "${TOMCAT_VERSION}"
    TOMCAT_SHA512 = "${TOMCAT_SHA512}"
    TCNATIVE_VERSION = "${TCNATIVE_VERSION}"
    TCNATIVE_SHA512 = "${TCNATIVE_SHA512}"
  }
  labels = {
    "org.label-schema.name" = "${PRODUCT_LINE} Tomcat"
    "org.opencontainers.image.title" = "${PRODUCT_LINE} Tomcat"
    "org.opencontainers.image.description" = "A base image shipping Tomcat for Alfresco Products"
  }
  tags = ["${REGISTRY}/${REGISTRY_NAMESPACE}/alfresco-base-tomcat:tomcat${TOMCAT_MAJOR}-${JDIST}${JAVA_MAJOR}-${DISTRIB_NAME}${DISTRIB_MAJOR}"]
  output = ["type=cacheonly"]
}

variable "ALFRESCO_REPO_USER_ID" {
  default = "33000"
}

variable "ALFRESCO_REPO_USER_NAME" {
  default = "alfresco"
}

target "repository" {
  context = "./repository"
  dockerfile = "Dockerfile"
  inherits = ["tomcat_base"]
  contexts = {
    tomcat_base = "target:tomcat_base"
  }
  args = {
    ALFRESCO_REPO_GROUP_ID = "${ALFRESCO_GROUP_ID}"
    ALFRESCO_REPO_GROUP_NAME = "${ALFRESCO_GROUP_NAME}"
    ALFRESCO_REPO_USER_ID = "${ALFRESCO_REPO_USER_ID}"
    ALFRESCO_REPO_USER_NAME = "${ALFRESCO_REPO_USER_NAME}"
    ALFRESCO_REPO_ARTIFACT = "${repository_editions.artifact}"
    ALFRESCO_REPO_EDITION = "${repository_editions.name}"
  }
  labels = {
    "org.label-schema.name" = "${PRODUCT_LINE} Content Repository (${repository_editions.name})"
    "org.opencontainers.image.title" = "${PRODUCT_LINE} Content Repository (${repository_editions.name})"
    "org.opencontainers.image.description" = "Alfresco Content Services Repository ${repository_editions.name} edition"
  }
  tags = ["${REGISTRY}/${REGISTRY_NAMESPACE}/${repository_editions.image_name}:${TAG}"]
  output = ["type=docker"]
  platforms = split(",", "${TARGETARCH}")

  name = "repository_${repository_editions.name}"

  matrix = {
    repository_editions = [
      {
        artifact = "alfresco-content-services-community-distribution",
        image_name = "alfresco-content-repository-community",
        name = "community"
      },
      {
        artifact = "alfresco-content-services-distribution",
        image_name = "alfresco-content-repository",
        name = "enterprise"
      }
    ]
  }
}

variable "ALFRESCO_LIVEINDEX_USER_ID" {
  default = "33011"
}

variable "ALFRESCO_LIVEINDEX_USER_NAME" {
  default = "liveindexer"
}

target "search_liveindexing" {
  matrix = {
    liveindexing = [
      {
        artifact = "alfresco-elasticsearch-live-indexing-mediation",
        name = "mediation",
        context = "common"
      },
      {
        artifact = "alfresco-elasticsearch-live-indexing-metadata",
        name = "metadata",
        context = "common"
      },
      {
        artifact = "alfresco-elasticsearch-live-indexing-path",
        name = "path",
        context = "common"
      },
      {
        artifact = "alfresco-elasticsearch-live-indexing-content",
        name = "content",
        context = "common"
      },
      {
        artifact = "alfresco-elasticsearch-live-indexing",
        name = "all-in-one",
        context = "all-in-one"
      }
    ]
  }
  name = "${liveindexing.artifact}"
  args = {
    LIVEINDEXING = "${liveindexing.artifact}"
    ALFRESCO_LIVEINDEX_GROUP_ID = "${ALFRESCO_GROUP_ID}"
    ALFRESCO_LIVEINDEX_GROUP_NAME = "${ALFRESCO_GROUP_NAME}"
    ALFRESCO_LIVEINDEX_USER_ID = "${ALFRESCO_LIVEINDEX_USER_ID}"
    ALFRESCO_LIVEINDEX_USER_NAME = "${ALFRESCO_LIVEINDEX_USER_NAME}"
  }
  context = "./search/enterprise/${liveindexing.context}"
  dockerfile = "Dockerfile"
  inherits = ["java_base"]
  contexts = {
    java_base = "target:java_base"
  }
  labels = {
    "org.label-schema.name" = "${PRODUCT_LINE} Enterprise Search - ${liveindexing.name}"
    "org.opencontainers.image.title" = "${PRODUCT_LINE} Enterprise Search - ${liveindexing.name}"
    "org.opencontainers.image.description" = "${PRODUCT_LINE} Enterprise Search - ${liveindexing.name} live indexing"
  }
  tags = ["${REGISTRY}/${REGISTRY_NAMESPACE}/${liveindexing.artifact}:${TAG}"]
  output = ["type=docker"]
  platforms = split(",", "${TARGETARCH}")
}

variable "ALFRESCO_REINDEX_USER_ID" {
  default = "33011"
}

variable "ALFRESCO_REINDEX_USER_NAME" {
  default = "liveindexer"
}

target "search_reindexing" {
  context = "./search/enterprise/reindexing"
  dockerfile = "Dockerfile"
  inherits = ["java_base"]
  contexts = {
    java_base = "target:java_base"
  }
  args = {
    ALFRESCO_REINDEX_GROUP_ID = "${ALFRESCO_GROUP_ID}"
    ALFRESCO_REINDEX_GROUP_NAME = "${ALFRESCO_GROUP_NAME}"
    ALFRESCO_REINDEX_USER_ID = "${ALFRESCO_REINDEX_USER_ID}"
    ALFRESCO_REINDEX_USER_NAME = "${ALFRESCO_REINDEX_USER_NAME}"
  }
  labels = {
    "org.label-schema.name" = "${PRODUCT_LINE} Enterprise Search - reindexing"
    "org.opencontainers.image.title" = "${PRODUCT_LINE} Enterprise Search - reindexing"
    "org.opencontainers.image.description" = "${PRODUCT_LINE} Enterprise Search - reindexing component"
  }
  tags = ["${REGISTRY}/${REGISTRY_NAMESPACE}/alfresco-elasticsearch-reindexing:${TAG}"]
  output = ["type=docker"]
  platforms = split(",", "${TARGETARCH}")
}

variable "ALFRESCO_TROUTER_USER_NAME" {
  default = "trouter"
}

variable "ALFRESCO_TROUTER_USER_ID" {
  default = "33016"
}

target "ats_trouter" {
  context = "./ats/trouter"
  dockerfile = "Dockerfile"
  inherits = ["java_base"]
  contexts = {
    java_base = "target:java_base"
  }
  args = {
    ALFRESCO_TROUTER_GROUP_NAME = "${ALFRESCO_GROUP_NAME}"
    ALFRESCO_TROUTER_GROUP_ID = "${ALFRESCO_GROUP_ID}"
    ALFRESCO_TROUTER_USER_NAME = "${ALFRESCO_TROUTER_USER_NAME}"
    ALFRESCO_TROUTER_USER_ID = "${ALFRESCO_TROUTER_USER_ID}"
  }
  labels = {
    "org.label-schema.name" = "${PRODUCT_LINE} ATS Trouter"
    "org.opencontainers.image.title" = "${PRODUCT_LINE} ATS Trouter"
    "org.opencontainers.image.description" = "Alfresco Transform Service Trouter"
  }
  tags = ["${REGISTRY}/${REGISTRY_NAMESPACE}/alfresco-transform-router:${TAG}"]
  output = ["type=docker"]
  platforms = split(",", "${TARGETARCH}")
}

variable "ALFRESCO_SFS_USER_NAME" {
  default = "sfs"
}

variable "ALFRESCO_SFS_USER_ID" {
  default = "33030"
}

target "ats_sfs" {
  context = "./ats/sfs"
  dockerfile = "Dockerfile"
  inherits = ["java_base"]
  contexts = {
    java_base = "target:java_base"
  }
  args = {
    ALFRESCO_SFS_GROUP_NAME = "${ALFRESCO_GROUP_NAME}"
    ALFRESCO_SFS_GROUP_ID = "${ALFRESCO_GROUP_ID}"
    ALFRESCO_SFS_USER_NAME = "${ALFRESCO_SFS_USER_NAME}"
    ALFRESCO_SFS_USER_ID = "${ALFRESCO_SFS_USER_ID}"
  }
  labels = {
    "org.label-schema.name" = "${PRODUCT_LINE} ATS Shared File Store"
    "org.opencontainers.image.title" = "${PRODUCT_LINE} ATS Shared File Store"
    "org.opencontainers.image.description" = "Alfresco Transform Service ATS Shared File Store"
  }
  tags = ["${REGISTRY}/${REGISTRY_NAMESPACE}/alfresco-shared-file-store:${TAG}"]
  output = ["type=docker"]
  platforms = split(",", "${TARGETARCH}")
}

variable "ALFRESCO_IMAGEMAGICK_USER_NAME" {
  default = "imagemagick"
}

variable "ALFRESCO_IMAGEMAGICK_USER_ID" {
  default = "33002"
}

target "tengine_imagemagick" {
  context = "./tengine/imagemagick"
  dockerfile = "Dockerfile"
  inherits = ["java_base"]
  contexts = {
    java_base = "target:java_base"
  }
  args = {
    ALFRESCO_IMAGEMAGICK_GROUP_NAME = "${ALFRESCO_GROUP_NAME}"
    ALFRESCO_IMAGEMAGICK_GROUP_ID = "${ALFRESCO_GROUP_ID}"
    ALFRESCO_IMAGEMAGICK_USER_NAME = "${ALFRESCO_IMAGEMAGICK_USER_NAME}"
    ALFRESCO_IMAGEMAGICK_USER_ID = "${ALFRESCO_IMAGEMAGICK_USER_ID}"
  }
  labels = {
    "org.label-schema.name" = "${PRODUCT_LINE} Transform Engine Imagemagick"
    "org.opencontainers.image.title" = "${PRODUCT_LINE} Transform Engine Imagemagick"
    "org.opencontainers.image.description" = "Alfresco Transform Engine Imagemagick"
  }
  tags = ["${REGISTRY}/${REGISTRY_NAMESPACE}/alfresco-imagemagick:${TAG}"]
  output = ["type=docker"]
  platforms = split(",", "${TARGETARCH}")
}

variable "ALFRESCO_LIBREOFFICE_USER_NAME" {
  default = "libreoffice"
}

variable "ALFRESCO_LIBREOFFICE_USER_ID" {
  default = "33003"
}

target "tengine_libreoffice" {
  context = "./tengine/libreoffice"
  dockerfile = "Dockerfile"
  inherits = ["java_base"]
  contexts = {
    java_base = "target:java_base"
  }
  args = {
    ALFRESCO_LIBREOFFICE_GROUP_NAME = "${ALFRESCO_GROUP_NAME}"
    ALFRESCO_LIBREOFFICE_GROUP_ID = "${ALFRESCO_GROUP_ID}"
    ALFRESCO_LIBREOFFICE_USER_NAME = "${ALFRESCO_LIBREOFFICE_USER_NAME}"
    ALFRESCO_LIBREOFFICE_USER_ID = "${ALFRESCO_LIBREOFFICE_USER_ID}"
  }
  labels = {
    "org.label-schema.name" = "${PRODUCT_LINE} Transform Engine LibreOffice"
    "org.opencontainers.image.title" = "${PRODUCT_LINE} Transform Engine LibreOffice"
    "org.opencontainers.image.description" = "Alfresco Transform Engine LibreOffice"
  }
  tags = ["${REGISTRY}/${REGISTRY_NAMESPACE}/alfresco-libreoffice:${TAG}"]
  output = ["type=docker"]
  platforms = split(",", "${TARGETARCH}")
}

variable "ALFRESCO_MISC_USER_NAME" {
  default = "transform-misc"
}

variable "ALFRESCO_MISC_USER_ID" {
  default = "33006"
}

target "tengine_misc" {
  context = "./tengine/misc"
  dockerfile = "Dockerfile"
  inherits = ["java_base"]
  contexts = {
    java_base = "target:java_base"
  }
  args = {
    ALFRESCO_MISC_GROUP_NAME = "${ALFRESCO_GROUP_NAME}"
    ALFRESCO_MISC_GROUP_ID = "${ALFRESCO_GROUP_ID}"
    ALFRESCO_MISC_USER_NAME = "${ALFRESCO_MISC_USER_NAME}"
    ALFRESCO_MISC_USER_ID = "${ALFRESCO_MISC_USER_ID}"
  }
  labels = {
    "org.label-schema.name" = "${PRODUCT_LINE} Transform Engine Misc"
    "org.opencontainers.image.title" = "${PRODUCT_LINE} Transform Engine Misc"
    "org.opencontainers.image.description" = "Alfresco Transform Engine Misc"
  }
  tags = ["${REGISTRY}/${REGISTRY_NAMESPACE}/alfresco-transform-misc:${TAG}"]
  output = ["type=docker"]
  platforms = split(",", "${TARGETARCH}")
}

variable "ALFRESCO_TIKA_USER_NAME" {
  default = "tika"
}

variable "ALFRESCO_TIKA_USER_ID" {
  default = "33004"
}

target "tengine_tika" {
  context = "./tengine/tika"
  dockerfile = "Dockerfile"
  inherits = ["java_base"]
  contexts = {
    java_base = "target:java_base"
  }
  args = {
    ALFRESCO_TIKA_GROUP_NAME = "${ALFRESCO_GROUP_NAME}"
    ALFRESCO_TIKA_GROUP_ID = "${ALFRESCO_GROUP_ID}"
    ALFRESCO_TIKA_USER_NAME = "${ALFRESCO_TIKA_USER_NAME}"
    ALFRESCO_TIKA_USER_ID = "${ALFRESCO_TIKA_USER_ID}"
  }
  labels = {
    "org.label-schema.name" = "${PRODUCT_LINE} Transform Engine Tika"
    "org.opencontainers.image.title" = "${PRODUCT_LINE} Transform Engine Tika"
    "org.opencontainers.image.description" = "Alfresco Transform Engine Tika"
  }
  tags = ["${REGISTRY}/${REGISTRY_NAMESPACE}/alfresco-tika:${TAG}"]
  output = ["type=docker"]
  platforms = split(",", "${TARGETARCH}")
}

variable "ALFRESCO_PDFRENDERER_USER_NAME" {
  default = "pdf"
}

variable "ALFRESCO_PDFRENDERER_USER_ID" {
  default = "33001"
}

target "tengine_pdfrenderer" {
  context = "./tengine/pdfrenderer"
  dockerfile = "Dockerfile"
  inherits = ["java_base"]
  contexts = {
    java_base = "target:java_base"
  }
  args = {
    ALFRESCO_PDFRENDERER_GROUP_NAME = "${ALFRESCO_GROUP_NAME}"
    ALFRESCO_PDFRENDERER_GROUP_ID = "${ALFRESCO_GROUP_ID}"
    ALFRESCO_PDFRENDERER_USER_NAME = "${ALFRESCO_PDFRENDERER_USER_NAME}"
    ALFRESCO_PDFRENDERER_USER_ID = "${ALFRESCO_PDFRENDERER_USER_ID}"
  }
  labels = {
    "org.label-schema.name" = "${PRODUCT_LINE} Transform Engine PDF Renderer"
    "org.opencontainers.image.title" = "${PRODUCT_LINE} Transform Engine PDF Renderer"
    "org.opencontainers.image.description" = "Alfresco Transform Engine PDF Renderer"
  }
  tags = ["${REGISTRY}/${REGISTRY_NAMESPACE}/alfresco-pdf-renderer:${TAG}"]
  output = ["type=docker"]
  platforms = split(",", "${TARGETARCH}")
}

variable "ALFRESCO_AIO_USER_NAME" {
  default = "transform-all-in-one"
}

variable "ALFRESCO_AIO_USER_ID" {
  default = "33017"
}

target "tengine_aio" {
  context = "./tengine"
  dockerfile = "aio/Dockerfile"
  inherits = ["java_base"]
  contexts = {
    java_base = "target:java_base"
  }
  args = {
    ALFRESCO_AIO_GROUP_NAME = "${ALFRESCO_GROUP_NAME}"
    ALFRESCO_AIO_GROUP_ID = "${ALFRESCO_GROUP_ID}"
    ALFRESCO_AIO_USER_NAME = "${ALFRESCO_AIO_USER_NAME}"
    ALFRESCO_AIO_USER_ID = "${ALFRESCO_AIO_USER_ID}"
  }
  labels = {
    "org.label-schema.name" = "${PRODUCT_LINE} Transform Engine All In One"
    "org.opencontainers.image.title" = "${PRODUCT_LINE} Transform Engine All In One"
    "org.opencontainers.image.description" = "Alfresco Transform Engine All In One"
  }
  tags = ["${REGISTRY}/${REGISTRY_NAMESPACE}/alfresco-transform-core-aio:${TAG}"]
  output = ["type=docker"]
  platforms = split(",", "${TARGETARCH}")
}

variable "ALFRESCO_MSTEAMS_USER_NAME" {
  default = "ms-int-user"
}

variable "ALFRESCO_MSTEAMS_USER_ID" {
  default = "33041"
}

target "connector_msteams" {
  context = "./connector/msteams"
  dockerfile = "Dockerfile"
  inherits = ["java_base"]
  contexts = {
    java_base = "target:java_base"
  }
  args = {
    ALFRESCO_MSTEAMS_GROUP_NAME = "${ALFRESCO_GROUP_NAME}"
    ALFRESCO_MSTEAMS_GROUP_ID = "${ALFRESCO_GROUP_ID}"
    ALFRESCO_MSTEAMS_USER_NAME = "${ALFRESCO_MSTEAMS_USER_NAME}"
    ALFRESCO_MSTEAMS_USER_ID = "${ALFRESCO_MSTEAMS_USER_ID}"
  }
  labels = {
    "org.label-schema.name" = "${PRODUCT_LINE} Connector Microsoft Teams"
    "org.opencontainers.image.title" = "${PRODUCT_LINE} Connector Microsoft Teams"
    "org.opencontainers.image.description" = "Alfresco Connector Microsoft Teams"
  }
  tags = ["${REGISTRY}/${REGISTRY_NAMESPACE}/alfresco-ms-teams-service:${TAG}"]
  output = ["type=docker"]
  platforms = split(",", "${TARGETARCH}")
}

variable "ALFRESCO_MS365_USER_NAME" {
  default = "ooi-user"
}

variable "ALFRESCO_MS365_USER_ID" {
  default = "33006"
}

target "connector_ms365" {
  context = "./connector/ms365"
  dockerfile = "Dockerfile"
  inherits = ["java_base"]
  contexts = {
    java_base = "target:java_base"
  }
  args = {
    ALFRESCO_MS365_GROUP_NAME = "${ALFRESCO_GROUP_NAME}"
    ALFRESCO_MS365_GROUP_ID = "${ALFRESCO_GROUP_ID}"
    ALFRESCO_MS365_USER_NAME = "${ALFRESCO_MS365_USER_NAME}"
    ALFRESCO_MS365_USER_ID = "${ALFRESCO_MS365_USER_ID}"
  }
  labels = {
    "org.label-schema.name" = "${PRODUCT_LINE} Microsoft 365 Connector"
    "org.opencontainers.image.title" = "${PRODUCT_LINE} Microsoft 365 Connector"
    "org.opencontainers.image.description" = "Alfresco Microsoft 365 Connector"
  }
  tags = ["${REGISTRY}/${REGISTRY_NAMESPACE}/alfresco-ooi-service:${TAG}"]
  output = ["type=docker"]
  platforms = split(",", "${TARGETARCH}")
}

variable "ALFRESCO_SHARE_USER_NAME" {
  default = "share"
}

variable "ALFRESCO_SHARE_USER_ID" {
  default = "33010"
}

target "share" {
  context = "./share"
  dockerfile = "Dockerfile"
  inherits = ["tomcat_base"]
  contexts = {
    tomcat_base = "target:tomcat_base"
  }
  args = {
    ALFRESCO_SHARE_GROUP_NAME = "${ALFRESCO_GROUP_NAME}"
    ALFRESCO_SHARE_GROUP_ID = "${ALFRESCO_GROUP_ID}"
    ALFRESCO_SHARE_USER_NAME = "${ALFRESCO_SHARE_USER_NAME}"
    ALFRESCO_SHARE_USER_ID = "${ALFRESCO_SHARE_USER_ID}"
    ALFRESCO_SHARE_ARTIFACT = "${share_editions.artifact}"
  }
  labels = {
    "org.label-schema.name" = "${PRODUCT_LINE} Share"
    "org.opencontainers.image.title" = "${PRODUCT_LINE} Share"
    "org.opencontainers.image.description" = "Alfresco Share"
  }
  tags = ["${REGISTRY}/${REGISTRY_NAMESPACE}/${share_editions.image_name}:${TAG}"]
  output = ["type=docker"]
  platforms = split(",", "${TARGETARCH}")

  name = "share_${share_editions.name}"

  matrix = {
    share_editions = [
      {
        artifact = "alfresco-content-services-community-distribution",
        image_name = "alfresco-share-community",
        name = "community"
      },
      {
        artifact = "alfresco-content-services-share-distribution",
        image_name = "alfresco-share",
        name = "enterprise"
      }
    ]
  }
}

variable "ALFRESCO_SOLR_DIST_DIR" {
  default = "/opt/alfresco-search-services"
}

variable "ALFRESCO_SOLR_USER_NAME" {
  default = "solr"
}

variable "ALFRESCO_SOLR_USER_ID" {
  default = "33007"
}

target "search_service" {
  context = "./search/service"
  dockerfile = "Dockerfile"
  inherits = ["java_base"]
  contexts = {
    java_base = "target:java_base"
  }
  args = {
    ALFRESCO_SOLR_GROUP_NAME = "${ALFRESCO_GROUP_NAME}"
    ALFRESCO_SOLR_GROUP_ID = "${ALFRESCO_GROUP_ID}"
    ALFRESCO_SOLR_USER_NAME = "${ALFRESCO_SOLR_USER_NAME}"
    ALFRESCO_SOLR_USER_ID = "${ALFRESCO_SOLR_USER_ID}"
    ALFRESCO_SOLR_DIST_DIR = "${ALFRESCO_SOLR_DIST_DIR}"
  }
  labels = {
    "org.label-schema.name" = "${PRODUCT_LINE} Search Service (Solr)"
    "org.opencontainers.image.title" = "${PRODUCT_LINE} Search Service (Solr)"
    "org.opencontainers.image.description" = "Alfresco Search Service (Solr)"
  }
  tags = ["${REGISTRY}/${REGISTRY_NAMESPACE}/alfresco-search-service:${TAG}"]
  output = ["type=docker"]
  platforms = split(",", "${TARGETARCH}")
}

target "acc" {
  context = "./adf-apps/acc"
  dockerfile = "Dockerfile"
  labels = {
    "org.label-schema.name" = "${PRODUCT_LINE} Control Center"
    "org.opencontainers.image.title" = "${PRODUCT_LINE} Control Center"
    "org.opencontainers.image.description" = "Alfresco Control Center"
  }
  tags = ["${REGISTRY}/${REGISTRY_NAMESPACE}/alfresco-control-center:${TAG}"]
  output = ["type=docker"]
  platforms = split(",", "${TARGETARCH}")
}

target "adw" {
  context = "./adf-apps/adw"
  dockerfile = "Dockerfile"
  labels = {
    "org.label-schema.name" = "${PRODUCT_LINE} Digital Workspace"
    "org.opencontainers.image.title" = "${PRODUCT_LINE} Digital Workspace"
    "org.opencontainers.image.description" = "Alfresco Digital Workspace"
  }
  tags = ["${REGISTRY}/${REGISTRY_NAMESPACE}/alfresco-digital-workspace:${TAG}"]
  output = ["type=docker"]
  platforms = split(",", "${TARGETARCH}")
}

variable "ALFRESCO_SYNC_USER_NAME" {
  default = "dsync"
}

variable "ALFRESCO_SYNC_USER_ID" {
  default = "33020"
}

target "sync" {
  context = "./sync"
  dockerfile = "Dockerfile"
  inherits = ["java_base"]
  contexts = {
    java_base = "target:java_base"
  }
  args = {
    ALFRESCO_SYNC_GROUP_NAME = "${ALFRESCO_GROUP_NAME}"
    ALFRESCO_SYNC_GROUP_ID = "${ALFRESCO_GROUP_ID}"
    ALFRESCO_SYNC_USER_NAME = "${ALFRESCO_SYNC_USER_NAME}"
    ALFRESCO_SYNC_USER_ID = "${ALFRESCO_SYNC_USER_ID}"
  }
  labels = {
    "org.label-schema.name" = "${PRODUCT_LINE} Sync Service"
    "org.opencontainers.image.title" = "${PRODUCT_LINE} Sync Service"
    "org.opencontainers.image.description" = "Alfresco Sync Service"
  }
  tags = ["${REGISTRY}/${REGISTRY_NAMESPACE}/alfresco-sync-service:${TAG}"]
  output = ["type=docker"]
  platforms = split(",", "${TARGETARCH}")
}

variable "ALFRESCO_AUDIT_STORAGE_USER_NAME" {
  default = "auditstorage"
}

variable "ALFRESCO_AUDIT_STORAGE_USER_ID" {
  default = "33008"
}

target "audit_storage" {
  context = "./audit-storage"
  dockerfile = "Dockerfile"
  inherits = ["java_base"]
  contexts = {
    java_base = "target:java_base"
  }
  args = {
    ALFRESCO_AUDIT_STORAGE_GROUP_NAME = "${ALFRESCO_GROUP_NAME}"
    ALFRESCO_AUDIT_STORAGE_GROUP_ID = "${ALFRESCO_GROUP_ID}"
    ALFRESCO_AUDIT_STORAGE_USER_NAME = "${ALFRESCO_AUDIT_STORAGE_USER_NAME}"
    ALFRESCO_AUDIT_STORAGE_USER_ID = "${ALFRESCO_AUDIT_STORAGE_USER_ID}"
  }
  labels = {
    "org.label-schema.name" = "${PRODUCT_LINE} Audit Storage"
    "org.opencontainers.image.title" = "${PRODUCT_LINE} repository's Audit Storage"
    "org.opencontainers.image.description" = "Alfresco Audit Storage for repository events"
  }
  tags = ["${REGISTRY}/${REGISTRY_NAMESPACE}/alfresco-audit-storage:${TAG}"]
  output = ["type=docker"]
  platforms = split(",", "${TARGETARCH}")
}

variable "HXINSIGHT_USER_NAME" {
  default = "hsinsight"
}

variable "HXINSIGHT_USER_ID" {
  default = "33009"
}

target "hxinsight_connector_bulk_ingester" {
  context = "./hxinsight-connector-bulk-ingester"
  dockerfile = "Dockerfile"
  inherits = ["java_base"]
  contexts = {
    java_base = "target:java_base"
  }
  args = {
    HXINSIGHT_CONNECTOR_GROUP_NAME = "${ALFRESCO_GROUP_NAME}"
    HXINSIGHT_CONNECTOR_GROUP_ID = "${ALFRESCO_GROUP_ID}"
    HXINSIGHT_CONNECTOR_USER_NAME = "${HXINSIGHT_USER_NAME}"
    HXINSIGHT_CONNECTOR_USER_ID = "${HXINSIGHT_USER_ID}"
  }
  labels = {
    "org.label-schema.name" = "${PRODUCT_LINE} HxInsight Connector Bulk Ingester"
    "org.opencontainers.image.title" = "${PRODUCT_LINE} repository's HxInsight Connector Bulk Ingester"
    "org.opencontainers.image.description" = "Alfresco HxInsight Connector Bulk Ingester"
  }
  tags = ["${REGISTRY}/${REGISTRY_NAMESPACE}/alfresco-hxinsight-connector-bulk-ingester:${TAG}"]
  output = ["type=docker"]
  platforms = split(",", "${TARGETARCH}")
}

target "hxinsight_connector_live_ingester" {
  context = "./hxinsight-connector-live-ingester"
  dockerfile = "Dockerfile"
  inherits = ["java_base"]
  contexts = {
    java_base = "target:java_base"
  }
  args = {
    HXINSIGHT_CONNECTOR_GROUP_NAME = "${ALFRESCO_GROUP_NAME}"
    HXINSIGHT_CONNECTOR_GROUP_ID = "${ALFRESCO_GROUP_ID}"
    HXINSIGHT_CONNECTOR_USER_NAME = "${HXINSIGHT_USER_NAME}"
    HXINSIGHT_CONNECTOR_USER_ID = "${HXINSIGHT_USER_ID}"
  }
  labels = {
    "org.label-schema.name" = "${PRODUCT_LINE} HxInsight Connector Live Ingester"
    "org.opencontainers.image.title" = "${PRODUCT_LINE} repository's HxInsight Connector Live Ingester"
    "org.opencontainers.image.description" = "Alfresco HxInsight Connector Live Ingester"
  }
  tags = ["${REGISTRY}/${REGISTRY_NAMESPACE}/alfresco-hxinsight-connector-live-ingester:${TAG}"]
  output = ["type=docker"]
  platforms = split(",", "${TARGETARCH}")
}

target "hxinsight_connector_prediction_applier" {
  context = "./hxinsight-connector-prediction-applier"
  dockerfile = "Dockerfile"
  inherits = ["java_base"]
  contexts = {
    java_base = "target:java_base"
  }
  args = {
    HXINSIGHT_CONNECTOR_GROUP_NAME = "${ALFRESCO_GROUP_NAME}"
    HXINSIGHT_CONNECTOR_GROUP_ID = "${ALFRESCO_GROUP_ID}"
    HXINSIGHT_CONNECTOR_USER_NAME = "${HXINSIGHT_USER_NAME}"
    HXINSIGHT_CONNECTOR_USER_ID = "${HXINSIGHT_USER_ID}"
  }
  labels = {
    "org.label-schema.name" = "${PRODUCT_LINE} HxInsight Connector Prediction Applier"
    "org.opencontainers.image.title" = "${PRODUCT_LINE} repository's HxInsight Connector Prediction Applier"
    "org.opencontainers.image.description" = "Alfresco HxInsight Connector Prediction Applier"
  }
  tags = ["${REGISTRY}/${REGISTRY_NAMESPACE}/alfresco-hxinsight-connector-prediction-applier:${TAG}"]
  output = ["type=docker"]
  platforms = split(",", "${TARGETARCH}")
}
