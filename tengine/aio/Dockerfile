FROM java_base

ENV JAVA_OPTS_CONTAINER_FLAGS=-XX:MaxRAMPercentage=80

EXPOSE 8090

ARG ALFRESCO_AIO_GROUP_NAME
ARG ALFRESCO_AIO_GROUP_ID
ARG ALFRESCO_AIO_USER_NAME
ARG ALFRESCO_AIO_USER_ID
ARG DISTRIB_MAJOR
ARG TARGETARCH

# microdnf cannot install an rpm from a URL
RUN --mount=type=bind,source=/,target=/dist \
    [ "$TARGETARCH" == 'arm64' ] && export PKGARCH='-aarch64' PDFARCH='-arm'; \
    PKG_MGR=$(command -v dnf || command -v microdnf) && \
    rpm -Uvh --replacepkgs https://dl.fedoraproject.org/pub/epel/epel-release-latest-${DISTRIB_MAJOR}.noarch.rpm && \
    $PKG_MGR install -y cairo cups-libs libSM libGLU perl-Image-ExifTool && \
    mkdir /tmp/dist && \
    $PKG_MGR install -y /dist/imagemagick/imagemagick-distribution*-el${DISTRIB_MAJOR}${PKGARCH}.rpm /dist/imagemagick/libs/imagemagick-distribution*-libs-el${DISTRIB_MAJOR}${PKGARCH}.rpm && \
    tar xzf /dist/pdfrenderer/*-linux${PDFARCH}.tgz -C /usr/bin alfresco-pdf-renderer && \
    if [ "$TARGETARCH" == 'arm64' ]; then \
        $PKG_MGR --enablerepo=devel install -y libreoffice && \
        update-alternatives --set java java-17-openjdk.aarch64; \
    else \
        tar xzf /dist/libreoffice/*.gz -C /tmp/dist && \
        $PKG_MGR install -y /tmp/dist/LibreOffice*/RPMS/*.rpm; \
    fi && \
    rm -rf /tmp/dist && \
    $PKG_MGR clean all && rm -rf /var/cache/dnf /var/cache/yum

COPY aio/alfresco-transform-core-aio*.jar /opt/app.jar

RUN groupadd -g ${ALFRESCO_AIO_GROUP_ID} ${ALFRESCO_AIO_GROUP_NAME} && \
    useradd -lu ${ALFRESCO_AIO_USER_ID} -g ${ALFRESCO_AIO_GROUP_NAME} ${ALFRESCO_AIO_USER_NAME} && \
    chgrp ${ALFRESCO_AIO_GROUP_NAME} /opt/app.jar

USER ${ALFRESCO_AIO_USER_NAME}

HEALTHCHECK --interval=20s --timeout=10s --retries=3 --start-period=30s \
  CMD curl -f http://localhost:8090/live || exit 1

COPY aio/entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
