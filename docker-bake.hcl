group "default" {
  targets = ["content_service", "enterprise-search"]
}

group "content_service" {
  targets = ["repository"]
}

group "enterprise-search" {
  targets = ["search_liveindexing"]
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
  tags = ["alfresco-base-java:${JDIST}${JAVA_MAJOR}-${DISTRIB_NAME}${DISTRIB_MAJOR}"]
  output = ["type=docker"]
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
  tags = ["alfresco-base-tomcat:tomcat${TOMCAT_MAJOR}-${JDIST}${JAVA_MAJOR}-${DISTRIB_NAME}${DISTRIB_MAJOR}"]
  output = ["type=docker"]
}

target "repository" {
  context = "./repository"
  dockerfile = "Dockerfile"
  inherits = ["tomcat_base"]
  contexts = {
    tomcat_base = "target:tomcat_base"
  }
  labels = {
    "org.opencontainers.image.title" = "${PRODUCT_LINE} Content Repository"
    "org.opencontainers.image.description" = "Alfresco Content Services Repository"
  }
  tags = ["alfresco-content-repository:latest"]
  output = ["type=docker"]
}

target "search_liveindexing" {
  matrix = {
    liveindexing = ["metadata", "path"]
  }
  name = "search_liveindexing-${liveindexing}"
  args = {
    LIVEINDEXING = "${liveindexing}"
  }
  dockerfile = "./search/enterprise/common/Dockerfile"
  inherits = ["java_base"]
  contexts = {
    java_base = "target:java_base"
  }
  labels = {
    "org.opencontainers.image.title" = "${PRODUCT_LINE} Enterprise Search - ${liveindexing}"
    "org.opencontainers.image.description" = "${PRODUCT_LINE} Enterprise Search - ${liveindexing} live indexing"
  }
  tags = ["alfresco-elasticsearch-live-indexing-${LIVEINDEXING}:latest"]
  output = ["type=docker"]
}