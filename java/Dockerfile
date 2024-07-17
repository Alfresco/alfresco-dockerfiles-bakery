# Alfresco Base Java Image
ARG DISTRIB_NAME
ARG DISTRIB_MAJOR
ARG IMAGE_BASE_LOCATION=docker.io/rockylinux:9

FROM ${IMAGE_BASE_LOCATION} AS rhlike

ARG JDIST
ARG JAVA_MAJOR

ENV JAVA_HOME /etc/alternatives/jre
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

RUN \
  yum update --security -y && \
  yum install -y langpacks-en java-${JAVA_MAJOR}-openjdk-headless && \
  yum clean all && rm -rf /var/cache/yum

FROM rhlike AS rockylinux8
FROM rhlike AS rockylinux9
FROM rhlike AS rhel8

FROM ${DISTRIB_NAME}${DISTRIB_MAJOR}
ARG DISTRIB_NAME
ARG DISTRIB_MAJOR
ARG JAVA_MAJOR
ARG CREATED
ARG REVISION
LABEL org.label-schema.schema-version="1.0" \
    org.label-schema.name="Alfresco Base Java Image" \
    org.label-schema.vendor="Alfresco" \
    org.label-schema.build-date="$CREATED" \
    org.opencontainers.image.title="Alfresco Base Java Image" \
    org.opencontainers.image.vendor="Alfresco" \
    org.opencontainers.image.created="$CREATED" \
    org.opencontainers.image.revision="$REVISION" \
    org.opencontainers.image.source="https://github.com/Alfresco/alfresco-docker-base-java"

RUN $JAVA_HOME/bin/java -version
