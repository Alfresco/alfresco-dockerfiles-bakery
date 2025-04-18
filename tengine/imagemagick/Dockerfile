FROM java_base

EXPOSE 8090

ENV JAVA_OPTS_CONTAINER_FLAGS=-XX:MaxRAMPercentage=80

ARG ALFRESCO_IMAGEMAGICK_GROUP_NAME
ARG ALFRESCO_IMAGEMAGICK_GROUP_ID
ARG ALFRESCO_IMAGEMAGICK_USER_NAME
ARG ALFRESCO_IMAGEMAGICK_USER_ID
ARG DISTRIB_MAJOR
ARG TARGETARCH

COPY alfresco-transform-imagemagick*.jar /opt/app.jar

RUN --mount=type=bind,source=/,target=/dist \
    [ "$TARGETARCH" == 'arm64' ] && export PKGARCH='-aarch64'; \
    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-${DISTRIB_MAJOR}.noarch.rpm; \
    yum localinstall -y /dist/imagemagick-distribution-*-el${DISTRIB_MAJOR}${PKGARCH}.rpm /dist/libs/imagemagick-distribution-*-libs-el${DISTRIB_MAJOR}${PKGARCH}.rpm; \
    yum clean all && rm -rf /var/cache/yum

RUN groupadd -g ${ALFRESCO_IMAGEMAGICK_GROUP_ID} ${ALFRESCO_IMAGEMAGICK_GROUP_NAME} && \
    useradd -lu ${ALFRESCO_IMAGEMAGICK_USER_ID} -g ${ALFRESCO_IMAGEMAGICK_GROUP_NAME} ${ALFRESCO_IMAGEMAGICK_USER_NAME} && \
    chgrp ${ALFRESCO_IMAGEMAGICK_GROUP_NAME} /opt/app.jar

USER ${ALFRESCO_IMAGEMAGICK_USER_NAME}

HEALTHCHECK --interval=20s --timeout=10s --retries=3 --start-period=30s \
  CMD curl -f http://localhost:8090/live || exit 1

COPY entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
