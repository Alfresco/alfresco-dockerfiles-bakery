# Alfresco Base Java Image
ARG DISTRIB_NAME
ARG DISTRIB_MAJOR
ARG IMAGE_BASE_LOCATION

FROM ${IMAGE_BASE_LOCATION} AS rhlike

ARG JDIST
ARG JAVA_MAJOR

ENV JAVA_HOME /etc/alternatives/jre
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

RUN \
  yum update --security -y && \
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
