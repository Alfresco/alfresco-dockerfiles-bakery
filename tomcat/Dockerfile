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
RUN apt-get -y update && apt-get -y install --no-install-recommends ca-certificates gnupg xmlstarlet curl gpg && apt-get clean && rm -rf /var/lib/apt/lists/*; \
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
    curl -fsSLo tcnative${filetype} ${active_mirror}/tomcat/tomcat-connectors/native/${TCNATIVE_VERSION}/source/tomcat-native-${TCNATIVE_VERSION}-src${filetype}; \
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
# Enable environment variable substitution in Tomcat XML configs
# hadolint ignore=SC2016
RUN echo 'org.apache.tomcat.util.digester.PROPERTY_SOURCE=org.apache.tomcat.util.digester.EnvironmentPropertySource' >> conf/catalina.properties
# hadolint ignore=SC2016
RUN connector='/Server/Service[@name="Catalina"]/Connector[@protocol="HTTP/1.1"]'; \
  host='/Server/Service[@name="Catalina"]/Engine[@name="Catalina"]/Host[@name="localhost"]'; \
  version_logger='/Server/Listener[@className="org.apache.catalina.startup.VersionLoggerListener"]'; \
  if [ "$TOMCAT_MAJOR" = "11" ]; then \
    internal_proxies='TOMCAT_REMOTE_IP_INTERNAL_PROXIES:-10/8,172.16/12,192.168/16,169.254/16,100.64/10,127/8,::1,fe80::/10,fc00::/7'; \
  else \
    internal_proxies='TOMCAT_REMOTE_IP_INTERNAL_PROXIES_TOMCAT10_REGEX'; \
  fi; \
  xmlstarlet ed -L \
  # Remove comments
  -d '//comment()' \
  # Disable shutdown port
  -d '/Server/@shutdown' -u '/Server/@port' -v '${TOMCAT_SHUTDOWN_PORT:--1}' \
  # Remove server banner
  -u "$connector/@Server" -v "" \
  # HTTP connector sizing and timeouts
  -u "$connector/@port" -v '${TOMCAT_HTTP_PORT:-8080}' \
  -u "$connector/@connectionTimeout" -v '${TOMCAT_HTTP_CONNECTION_TIMEOUT:-20000}' \
  -a "$connector" -t attr -n maxThreads -v '${TOMCAT_HTTP_MAX_THREADS:-200}' \
  -a "$connector" -t attr -n minSpareThreads -v '${TOMCAT_HTTP_MIN_SPARE_THREADS:-10}' \
  -a "$connector" -t attr -n acceptCount -v '${TOMCAT_HTTP_ACCEPT_COUNT:-100}' \
  -a "$connector" -t attr -n maxConnections -v '${TOMCAT_HTTP_MAX_CONNECTIONS:-8192}' \
  -a "$connector" -t attr -n maxHttpHeaderSize -v '${TOMCAT_HTTP_MAX_HTTP_HEADER_SIZE:-8192}' \
  -a "$connector" -t attr -n maxPostSize -v '${TOMCAT_HTTP_MAX_POST_SIZE:-2097152}' \
  # Disable auto deployment of webapps (overridable via env vars at runtime)
  -a "$host" -t attr -n deployXML -v '${TOMCAT_DEPLOY_XML:-false}' \
  -u "$host/@autoDeploy" -v '${TOMCAT_AUTO_DEPLOY:-false}' \
  -u "$host/@unpackWARs" -v '${TOMCAT_UNPACK_WARS:-false}' \
  # Enable RemoteIP valve for better handling when behind reverse proxy
  -s "$host" -t elem -n 'Valve' \
  -a "$host/Valve[last()]" -t attr -n className -v org.apache.catalina.valves.RemoteIpValve \
  -a "$host/Valve[last()]" -t attr -n portHeader -v '${TOMCAT_REMOTE_IP_PORT_HEADER:-X-Forwarded-Port}' \
  -a "$host/Valve[last()]" -t attr -n remoteIpHeader -v '${TOMCAT_REMOTE_IP_HEADER:-X-Forwarded-For}' \
  -a "$host/Valve[last()]" -t attr -n protocolHeader -v '${TOMCAT_REMOTE_IP_PROTOCOL_HEADER:-X-Forwarded-Proto}' \
  -a "$host/Valve[last()]" -t attr -n internalProxies -v "\${$internal_proxies}" \
  -a "$host/Valve[last()]" -t attr -n trustedProxies -v '${TOMCAT_REMOTE_IP_TRUSTED_PROXIES:-}' \
  # Do not leak server info within error pages
  -s "$host" -t elem -n 'Valve' \
  -a "$host/Valve[last()]" -t attr -n className -v org.apache.catalina.valves.ErrorReportValve \
  -a "$host/Valve[last()]" -t attr -n showServerInfo -v '${TOMCAT_ERROR_REPORT_SHOW_SERVER_INFO:-false}' \
  -a "$host/Valve[last()]" -t attr -n showReport -v '${TOMCAT_ERROR_REPORT_SHOW_REPORT:-false}' \
  # Do not leak runtime arguments and variables in logs
  -a "$version_logger" -t attr -n logArgs -v '${TOMCAT_VERSION_LOGGER_LOG_ARGS:-false}' \
  -a "$version_logger" -t attr -n logEnv -v '${TOMCAT_VERSION_LOGGER_LOG_ENV:-false}' \
  -a "$version_logger" -t attr -n logProps -v '${TOMCAT_VERSION_LOGGER_LOG_PROPS:-false}' \
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
ARG TOMCAT_MAJOR

ENV CATALINA_HOME=/usr/local/tomcat
# let "Tomcat Native" live somewhere isolated
ENV TOMCAT_NATIVE_LIBDIR=$CATALINA_HOME/native-jni-lib
ENV LD_LIBRARY_PATH=$TOMCAT_NATIVE_LIBDIR
ENV PATH=$CATALINA_HOME/bin:$PATH

# Tomcat 10 only: regex-based internal proxies (will be removed when Tomcat 10 is deprecated).
# Tomcat 11+ uses CIDR notation directly, which is more readable and natively supported.
ENV TOMCAT_REMOTE_IP_INTERNAL_PROXIES_TOMCAT10_REGEX="10\.\d{1,3}\.\d{1,3}\.\d{1,3}|192\.168\.\d{1,3}\.\d{1,3}|169\.254\.\d{1,3}\.\d{1,3}|127\.\d{1,3}\.\d{1,3}\.\d{1,3}|100\.6[4-9]{1}\.\d{1,3}\.\d{1,3}|100\.[7-9]{1}\d{1}\.\d{1,3}\.\d{1,3}|100\.1[0-1]{1}\d{1}\.\d{1,3}\.\d{1,3}|100\.12[0-7]{1}\.\d{1,3}\.\d{1,3}|172\.1[6-9]{1}\.\d{1,3}\.\d{1,3}|172\.2[0-9]{1}\.\d{1,3}\.\d{1,3}|172\.3[0-1]{1}\.\d{1,3}\.\d{1,3}|0:0:0:0:0:0:0:1|::1|fe[89ab]\p{XDigit}:.*|f[cd]\p{XDigit}{2}+:.*"

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
# Verify placeholders resolve: a value holding a closing brace truncates silently
RUN out="$(TOMCAT_HTTP_PORT=9999 catalina.sh configtest 2>&1 || true)"; \
  grep -q 'http-nio-9999' <<<"$out" || { echo "$out"; echo "TOMCAT_* env vars are not applied to server.xml"; exit 1; }; \
  ! grep -qE '\$\{|Exception' <<<"$out" || { echo "$out"; echo "Unresolved placeholder or invalid value in server.xml"; exit 1; }; \
  rm -f logs/*
USER tomcat
EXPOSE 8080
# Starting tomcat with Security Manager
CMD ["catalina.sh", "run", "-security"]
