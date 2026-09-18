# syntax=docker/dockerfile:1
# check=skip=InvalidDefaultArgInFrom
# kics-scan disable=fd54f200-402c-4333-a5a4-36ef6709af2f
ARG DISTRIB_NAME=nodistro
ARG DISTRIB_MAJOR
ARG IMAGE_BASE_LOCATION
ARG IMAGE_BUILDER_LOCATION

# The ubi-micro base ships no package manager, so the payload is assembled with the
# builder image's dnf and microdnf is included for downstream images to install with.
FROM ${IMAGE_BUILDER_LOCATION} AS rootfs

ARG DISTRIB_MAJOR
ARG JAVA_MAJOR

RUN dnf install -y --installroot /rootfs --releasever ${DISTRIB_MAJOR} --nodocs \
    --setopt install_weak_deps=0 \
    microdnf gzip langpacks-en java-${JAVA_MAJOR}-openjdk-headless which procps && \
  dnf clean all --installroot /rootfs && \
  rm -rf /rootfs/var/cache/* /rootfs/var/log/*

FROM ${IMAGE_BASE_LOCATION} AS rhlike

ARG JDIST
ARG JAVA_MAJOR

ENV JAVA_HOME=/etc/alternatives/jre
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

COPY --from=rootfs /rootfs/ /

FROM rhlike AS rockylinux8
FROM rhlike AS rockylinux9
FROM rhlike AS rhel8

FROM ${DISTRIB_NAME}${DISTRIB_MAJOR}
ARG DISTRIB_NAME
ARG DISTRIB_MAJOR
ARG JAVA_MAJOR

RUN $JAVA_HOME/bin/java -version
