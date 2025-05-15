# syntax=docker/dockerfile:1
# check=skip=InvalidDefaultArgInFrom
# kics-scan skip=fd54f200-402c-4333-a5a4-36ef6709af2f
ARG DISTRIB_NAME=nodistro
ARG DISTRIB_MAJOR
ARG IMAGE_BASE_LOCATION

FROM ${IMAGE_BASE_LOCATION} AS rhlike

ARG JDIST
ARG JAVA_MAJOR

ENV JAVA_HOME=/etc/alternatives/jre
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

RUN \
  yum update -y && \
  yum upgrade -y && \
  yum install -y langpacks-en java-${JAVA_MAJOR}-openjdk-headless which procps && \
  yum clean all && rm -rf /var/cache/yum

FROM rhlike AS rockylinux8
FROM rhlike AS rockylinux9
FROM rhlike AS rhel8

FROM ${DISTRIB_NAME}${DISTRIB_MAJOR}
ARG DISTRIB_NAME
ARG DISTRIB_MAJOR
ARG JAVA_MAJOR

RUN $JAVA_HOME/bin/java -version
