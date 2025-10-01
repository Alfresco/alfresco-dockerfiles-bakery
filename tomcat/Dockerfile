# hadolint global ignore=DL3033,DL3008
# Alfresco Base Tomcat Image
# see also https://github.com/docker-library/tomcat
ARG JAVA_MAJOR
ARG DISTRIB_NAME=nodistro
ARG DISTRIB_MAJOR

# Tomcat is downloaded and configured on debian as its a binary dist anyway
FROM debian:12-slim AS tomcat_dist
ARG TOMCAT_MAJOR
ARG TOMCAT_VERSION
ARG TOMCAT_SHA512
ARG TCNATIVE_VERSION
ARG TCNATIVE_SHA512
ENV APACHE_MIRRORS="https://archive.apache.org/dist https://dlcdn.apache.org https://downloads.apache.org"
ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
RUN apt-get -y update && apt-get -y install --no-install-recommends xmlstarlet curl gpg && apt-get clean && rm -rf /var/lib/apt/lists/*; \
  mkdir -p /build/{tcnative,tomcat}; \
  active_mirror=; \
  for mirror in $APACHE_MIRRORS; do \
    if curl -fsSL ${mirror}/tomcat/tomcat-${TOMCAT_MAJOR}/KEYS | gpg --import; then \
      active_mirror=$mirror; \
      break; \
    fi; \
  done; \
  [ -n "$active_mirror" ]; \
  \
  echo "Using mirror ${active_mirror}/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}"; \
  for filetype in '.tar.gz' '.tar.gz.asc'; do \
    curl -fsSLo tomcat${filetype} ${active_mirror}/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}${filetype}; \
    curl -fsSLo tcnative${filetype}  ${active_mirror}/tomcat/tomcat-connectors/native/${TCNATIVE_VERSION}/source/tomcat-native-${TCNATIVE_VERSION}-src${filetype}; \
  done; \
  \
  echo "$TOMCAT_SHA512 *tomcat.tar.gz" | sha512sum -c - || (echo "Checksum did't match: $(sha512sum *tomcat.tar.gz)" && exit 1); \
  echo "$TCNATIVE_SHA512 *tcnative.tar.gz" | sha512sum -c - || (echo "Checksum did't match: $(sha512sum *tcnative.tar.gz)" && exit 1); \
  \
  gpg --batch --verify tcnative.tar.gz.asc tcnative.tar.gz && \
  gpg --batch --verify tomcat.tar.gz.asc tomcat.tar.gz && \
  tar -zxf tomcat.tar.gz -C /build/tomcat --strip-components=1 && \
  tar -zxf tcnative.tar.gz -C /build/tcnative --strip-components=1
WORKDIR /build/tomcat
# sh removes env vars it doesn't support (ones with periods)
# https://github.com/docker-library/tomcat/issues/77
RUN find ./bin/ -name '*.sh' -exec sed -ri 's|^#!/bin/sh$|#!/usr/bin/env bash|' '{}' +; \
  mkdir -p lib/org/apache/catalina/util
WORKDIR /build/tomcat/lib/org/apache/catalina/util
RUN printf "server.info=Alfresco servlet container/$TOMCAT_MAJOR\nserver.number=$TOMCAT_MAJOR" > ServerInfo.properties
WORKDIR /build/tomcat
RUN xmlstarlet ed -L \
  # Remove comments
  -d '//comment()' \
  # Disable shutdown port
  -d '/Server/@shutdown' -u '/Server/@port' -v -1 \
  # Remove server banner
  -u '/Server/Service[@name="Catalina"]/Connector[@port=8080]/@Server' -v "" \
  # Disable auto deployment of webapps
  -a '/Server/Service[@name="Catalina"]/Engine[@name="Catalina"]/Host[@name="localhost"]' -t attr -n deployXML -v false \
  -u '/Server/Service[@name="Catalina"]/Engine[@name="Catalina"]/Host[@name="localhost"]/@autoDeploy' -v false \
  -u '/Server/Service[@name="Catalina"]/Engine[@name="Catalina"]/Host[@name="localhost"]/@unpackWARs' -v false \
  # Enable RemoteIP valve for better handling when behind reverse proxy
  -s '/Server/Service[@name="Catalina"]/Engine[@name="Catalina"]/Host[@name="localhost"]' -t elem -n 'Valve' \
  -a '/Server/Service[@name="Catalina"]/Engine[@name="Catalina"]/Host[@name="localhost"]/Valve[last()]' -t attr -n className -v org.apache.catalina.valves.RemoteIpValve \
  -a '/Server/Service[@name="Catalina"]/Engine[@name="Catalina"]/Host[@name="localhost"]/Valve[last()]' -t attr -n portHeader -v X-Forwarded-Port \
  # Do not leak server info within error pages
  -s '/Server/Service[@name="Catalina"]/Engine[@name="Catalina"]/Host[@name="localhost"]' -t elem -n 'Valve' \
  -a '/Server/Service[@name="Catalina"]/Engine[@name="Catalina"]/Host[@name="localhost"]/Valve[last()]' -t attr -n className -v org.apache.catalina.valves.ErrorReportValve \
  -a '/Server/Service[@name="Catalina"]/Engine[@name="Catalina"]/Host[@name="localhost"]/Valve[last()]' -t attr -n showServerInfo -v false \
  -a '/Server/Service[@name="Catalina"]/Engine[@name="Catalina"]/Host[@name="localhost"]/Valve[last()]' -t attr -n showReport -v false \
  # Do not leak runtime arguments and variables in logs
  -a '/Server/Listener[@className="org.apache.catalina.startup.VersionLoggerListener"]' -t attr -n logArgs -v false \
  -a '/Server/Listener[@className="org.apache.catalina.startup.VersionLoggerListener"]' -t attr -n logEnv -v false \
  -a '/Server/Listener[@className="org.apache.catalina.startup.VersionLoggerListener"]' -t attr -n logProps -v false \
  conf/server.xml
# Remove unwanted files from distribution
RUN rm -fr webapps/* *.txt *.md RELEASE-NOTES logs/ temp/ work/ bin/*.bat

FROM java_base AS tcnative_build-rockylinux
ARG JAVA_MAJOR
ENV JAVA_HOME=/usr/lib/jvm/java-openjdk
ARG BUILD_DIR=/build
ARG INSTALL_DIR=/usr/local
COPY --from=tomcat_dist /build/tcnative $BUILD_DIR/tcnative
WORKDIR ${BUILD_DIR}/tcnative/native
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
RUN yum install -y gcc make openssl-devel expat-devel java-${JAVA_MAJOR}-openjdk-devel apr-devel redhat-rpm-config && yum clean all; \
  ./configure \
    --libdir=${INSTALL_DIR}/tcnative \
    --with-apr=/usr/bin/apr-1-config \
    --with-java-home="$JAVA_HOME"; \
  make -j "$(nproc)"; \
  make install

FROM tcnative_build-rockylinux AS tcnative_build-rhel

# hadolint ignore=DL3006
FROM tcnative_build-${DISTRIB_NAME} AS tcnative_build

FROM java_base AS apr_pkg-rockylinux
RUN yum install -y apr && yum clean all

FROM apr_pkg-rockylinux AS apr_pkg-rhel

# hadolint ignore=DL3006
FROM apr_pkg-${DISTRIB_NAME}

ENV CATALINA_HOME=/usr/local/tomcat
# let "Tomcat Native" live somewhere isolated
ENV TOMCAT_NATIVE_LIBDIR=$CATALINA_HOME/native-jni-lib
ENV LD_LIBRARY_PATH=$TOMCAT_NATIVE_LIBDIR
ENV PATH=$CATALINA_HOME/bin:$PATH
WORKDIR $CATALINA_HOME
# fix permissions (especially for running as non-root)
# https://github.com/docker-library/tomcat/issues/35
RUN groupadd --system tomcat && \
  useradd -M -s /bin/false --home $CATALINA_HOME --system --gid tomcat tomcat
COPY --chown=:tomcat --chmod=640 --from=tomcat_dist /build/tomcat $CATALINA_HOME
COPY --chown=:tomcat --chmod=640 --from=tcnative_build /usr/local/tcnative $TOMCAT_NATIVE_LIBDIR
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]
RUN mkdir -m 770 logs temp work && chgrp tomcat . logs temp work; \
  find . -type d -exec chmod ug+rx {} +; \
  chmod ug+rx bin/*.sh; \
  # verify Tomcat Native is working properly
  nativeLines="$(catalina.sh configtest 2>&1 | grep -c 'Loaded Apache Tomcat Native library')" && \
  test $nativeLines -ge 1 || { echo "Tomcat Native library not found or not working properly"; exit 1; }
USER tomcat
EXPOSE 8080
# Starting tomcat with Security Manager
CMD ["catalina.sh", "run", "-security"]
