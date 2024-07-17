group "default" {
  targets = ["java_base"]
}

variable "LABEL_VENDOR" {
  default = "Hyland Software, Inc."
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
  annotations = {
    "org.opencontainers.image.title" = "${PRODUCT_LINE} Java"
    "org.opencontainers.image.vendor" = "${LABEL_VENDOR}"
    "org.opencontainers.image.created" = "${CREATED}"
    "org.opencontainers.image.revision" = "${REVISION}"
  }
  tags = ["alfresco-base-java:${JDIST}${JAVA_MAJOR}-${DISTRIB_NAME}${DISTRIB_MAJOR}"]
  output = ["type=docker"]
}

variable "TOMCAT_MAJOR" {
  default = "9"
}

variable "TOMCAT_VERSION" {
  default = "9.0.89"
}

variable "TOMCAT_SHA512" {
  default = "aaa2851bdc7a2476b6793e95174965c1c861531f161d8a138e87f8532b1af4d4b3d92dd1ae890614a692e5f13fb2e6946a1ada888f21e9d7db1964616b4181f0"
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
    TOMCAT_VERSION = "9.0.89"
    TOMCAT_SHA512 = "${TOMCAT_SHA512}"
    TCNATIVE_VERSION = "${TCNATIVE_VERSION}"
    TCNATIVE_SHA512 = "${TCNATIVE_SHA512}"
    LABEL_NAME = "${PRODUCT_LINE} Tomcat"
  }
  annotations = {
    "org.opencontainers.image.title" = "${PRODUCT_LINE} Tomcat"
  }
  tags = ["alfresco-base-tomcat:tomcat${TOMCAT_MAJOR}-${JDIST}${JAVA_MAJOR}-${DISTRIB_NAME}${DISTRIB_MAJOR}"]
  output = ["type=docker"]
}
