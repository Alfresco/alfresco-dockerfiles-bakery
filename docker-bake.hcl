group "default" {
  targets = ["content_service", "enterprise-search", "ats", "tengines"]
}

group "content_service" {
  targets = ["repository"]
}

group "enterprise-search" {
  targets = ["search_liveindexing"]
}

group "ats" {
  targets = ["ats_trouter", "ats_sfs"]
}

group "tengines" {
  targets = ["tengine_libreoffice", "tengine_imagemagick", "tengine_tika", "tengine_pdfrenderer"]
}

variable "LABEL_VENDOR" {
  default = "Hyland Software, Inc."
}

variable "LABEL_AUTHOR" {
  default = "Alfresco OPS-Readiness"
}

variable "LABEL_SOURCE" {
  default = "https://github.com/Alfresco/alfresco-dockerfiles"
}

variable "CODE_REF" {
  default = "local"
}

variable "PRODUCT_LINE" {
  default = "Alfresco"
}

variable "CREATED" {
  default = formatdate("YYYY'-'MM'-'DD'T'hh':'mm':'ss'Z'", timestamp())
}

variable "REVISION" {
  default = "$GITHUB_RUN_NUMBER"
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

variable "ALFRESCO_REPO_USER_ID" {
  default = "33000"
}

variable "ALFRESCO_REPO_USER_NAME" {
  default = "alfresco"
}

target "java_base" {
  dockerfile = "./java/Dockerfile"
  args = {
    DISTRIB_NAME = "${DISTRIB_NAME}"
    DISTRIB_MAJOR = "${DISTRIB_MAJOR}"
    JDIST = "${JDIST}"
    IMAGE_BASE_LOCATION = "${IMAGE_BASE_LOCATION}"
    JAVA_MAJOR = "${JAVA_MAJOR}"
    LABEL_NAME = "${PRODUCT_LINE} Java"
    LABEL_VENDOR = "${LABEL_VENDOR}"
    CREATED = "${CREATED}"
    REVISION = "${REVISION}"
  }
  labels = {
    "org.label-schema.schema-version" = "1.0"
    "org.label-schema.name" = "${PRODUCT_LINE} Java"
    "org.label-schema.vendor" = "${LABEL_VENDOR}"
    "org.label-schema.build-date" = "${CREATED}"
    "org.label-schema.url" = "$LABEL_SOURCE"
    "org.label-schema.vcs-url" = "$LABEL_SOURCE"
    "org.label-schema.vcs-ref" = "$CODE_REF"
    "org.opencontainers.image.title" = "${PRODUCT_LINE} Java"
    "org.opencontainers.image.description" = "A base image shipping OpenJDK JRE ${JAVA_MAJOR} for Alfresco Products"
    "org.opencontainers.image.vendor" = "${LABEL_VENDOR}"
    "org.opencontainers.image.created" = "${CREATED}"
    "org.opencontainers.image.revision" = "${REVISION}"
    "org.opencontainers.image.url" = "$LABEL_SOURCE"
    "org.opencontainers.image.source" = "$LABEL_SOURCE"
    "org.opencontainers.image.authors" = "${LABEL_AUTHOR}"
  }
  tags = ["localhost/alfresco-base-java:${JDIST}${JAVA_MAJOR}-${DISTRIB_NAME}${DISTRIB_MAJOR}"]
  output = ["type=cacheonly"]
}

variable "TOMCAT_MAJOR" {
  default = "10"
}

variable "TOMCAT_VERSION" {
  default = "10.1.26"
}

variable "TOMCAT_SHA512" {
  default = "0a62e55c1ff9f8f04d7aff938764eac46c289eda888abf43de74a82ceb7d879e94a36ea3e5e46186bc231f07871fcc4c58f11e026f51d4487a473badb21e9355"
}

variable "TCNATIVE_VERSION" {
  default = "1.3.0"
}

variable "TCNATIVE_SHA512" {
  default = "5a6c7337280774525c97e36e24d7d278ba15edd63c66cec1b3e5ecdc472f8d0535e31eac83cf0bdc68810eb779e2a118d6b4f6238b509f69a71d037c905fa433"
}

target "tomcat_base" {
  dockerfile = "./tomcat/Dockerfile"
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
    LABEL_NAME = "${PRODUCT_LINE} Tomcat"
  }
  labels = {
    "org.opencontainers.image.title" = "${PRODUCT_LINE} Tomcat"
    "org.opencontainers.image.description" = "A base image shipping Tomcat for Alfresco Products"
  }
  tags = ["localhost/alfresco-base-tomcat:tomcat${TOMCAT_MAJOR}-${JDIST}${JAVA_MAJOR}-${DISTRIB_NAME}${DISTRIB_MAJOR}"]
  output = ["type=cacheonly"]
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
  }
  labels = {
    "org.opencontainers.image.title" = "${PRODUCT_LINE} Content Repository"
    "org.opencontainers.image.description" = "Alfresco Content Services Repository"
  }
  tags = ["localhost/alfresco-content-repository:latest"]
  output = ["type=docker"]
}

target "search_liveindexing" {
  matrix = {
    liveindexing = [
      {
        artifact = "alfresco-elasticsearch-live-indexing-metadata",
        name = "metadata"
      },
      {
        artifact = "alfresco-elasticsearch-live-indexing-path",
        name = "path"
      },
      {
        artifact = "alfresco-elasticsearch-live-indexing-content",
        name = "content"
      },
      {
        artifact = "alfresco-elasticsearch-live-indexing",
        name = "all-in-one"
      }
    ]
  }
  name = "${liveindexing.artifact}"
  args = {
    LIVEINDEXING = "${liveindexing.artifact}"
  }
  dockerfile = "./search/enterprise/common/Dockerfile"
  inherits = ["java_base"]
  contexts = {
    java_base = "target:java_base"
  }
  labels = {
    "org.opencontainers.image.title" = "${PRODUCT_LINE} Enterprise Search - ${liveindexing.name}"
    "org.opencontainers.image.description" = "${PRODUCT_LINE} Enterprise Search - ${liveindexing.name} live indexing"
  }
  tags = ["localhost/${liveindexing.artifact}:latest"]
  output = ["type=docker"]
}

variable "ALFRESCO_TROUTER_USER_NAME" {
  default = "trouter"
}

variable "ALFRESCO_TROUTER_USER_ID" {
  default = "33016"
}

target "ats_trouter" {
  dockerfile = "./ats/trouter/Dockerfile"
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
    "org.opencontainers.image.title" = "${PRODUCT_LINE} ATS Trouter"
    "org.opencontainers.image.description" = "Alfresco Transform Service Trouter"
  }
  tags = ["localhost/alfresco-transform-router:latest"]
  output = ["type=docker"]
}

variable "ALFRESCO_SFS_USER_NAME" {
  default = "sfs"
}

variable "ALFRESCO_SFS_USER_ID" {
  default = "33030"
}

target "ats_sfs" {
  dockerfile = "./ats/sfs/Dockerfile"
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
    "org.opencontainers.image.title" = "${PRODUCT_LINE} ATS Shared File Store"
    "org.opencontainers.image.description" = "Alfresco Transform Service ATS Shared File Store"
  }
  tags = ["localhost/alfresco-shared-file-store:latest"]
  output = ["type=docker"]
}

variable "ALFRESCO_IMAGEMAGICK_USER_NAME" {
  default = "imagemagick"
}

variable "ALFRESCO_IMAGEMAGICK_USER_ID" {
  default = "33002"
}

target "tengine_imagemagick" {
  dockerfile = "./tengine/imagemagick/Dockerfile"
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
    "org.opencontainers.image.title" = "${PRODUCT_LINE} Transform Engine Imagemagick"
    "org.opencontainers.image.description" = "Alfresco Transform Engine Imagemagick"
  }
  tags = ["localhost/alfresco-imagemagick:latest"]
  output = ["type=docker"]
}

variable "ALFRESCO_LIBREOFFICE_USER_NAME" {
  default = "libreoffice"
}

variable "ALFRESCO_LIBREOFFICE_USER_ID" {
  default = "33003"
}

target "tengine_libreoffice" {
  dockerfile = "./tengine/libreoffice/Dockerfile"
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
    "org.opencontainers.image.title" = "${PRODUCT_LINE} Transform Engine LibreOffice"
    "org.opencontainers.image.description" = "Alfresco Transform Engine LibreOffice"
  }
  tags = ["localhost/alfresco-libreoffice:latest"]
  output = ["type=docker"]
}

variable "ALFRESCO_TIKA_USER_NAME" {
  default = "tika"
}

variable "ALFRESCO_TIKA_USER_ID" {
  default = "33004"
}

target "tengine_tika" {
  dockerfile = "./tengine/tika/Dockerfile"
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
    "org.opencontainers.image.title" = "${PRODUCT_LINE} Transform Engine Tika"
    "org.opencontainers.image.description" = "Alfresco Transform Engine Tika"
  }
  tags = ["localhost/alfresco-tika:latest"]
  output = ["type=docker"]
}

variable "ALFRESCO_PDFRENDERER_USER_NAME" {
  default = "pdf"
}

variable "ALFRESCO_PDFRENDERER_USER_ID" {
  default = "33001"
}

target "tengine_pdfrenderer" {
  dockerfile = "./tengine/pdfrenderer/Dockerfile"
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
    "org.opencontainers.image.title" = "${PRODUCT_LINE} Transform Engine PDF Renderer"
    "org.opencontainers.image.description" = "Alfresco Transform Engine PDF Renderer"
  }
  tags = ["localhost/alfresco-pdf-renderer:latest"]
  output = ["type=docker"]
}
