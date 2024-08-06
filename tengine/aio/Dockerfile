FROM java_base

ENV JAVA_OPTS_CONTAINER_FLAGS=-XX:MaxRAMPercentage=80

ENV COMMON_PATH=tengine
ENV AIO_COMMON_PATH=tengine/aio
ENV IMAGEMAGICK_DEP_RPM_URL=https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
ENV TIKA_DEP_RPM_URL=https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

EXPOSE 8090

ARG ALFRESCO_AIO_GROUP_NAME
ARG ALFRESCO_AIO_GROUP_ID
ARG ALFRESCO_AIO_USER_NAME
ARG ALFRESCO_AIO_USER_ID

RUN --mount=type=bind,source=${COMMON_PATH},target=/dist \
    mkdir /tmp/dist && \
    tar xzf /dist/libreoffice/*.gz -C /tmp/dist && \
    yum localinstall -y /tmp/dist/LibreOffice*/RPMS/*.rpm && \
    yum install -y cairo cups-libs libSM libGLU && \
    yum install -y $IMAGEMAGICK_DEP_RPM_URL && \
    yum install -y /dist/imagemagick/imagemagick-distribution-el9.rpm /dist/imagemagick/libs/imagemagick-distribution-libs-el9.rpm && \
    tar xzf /dist/pdfrenderer/*.tgz -C /usr/bin && \
    yum install -y ${TIKA_DEP_RPM_URL} && \
    yum -y install perl-Image-ExifTool && \
    rm -rf /tmp/dist && \
    yum clean all

ADD ${AIO_COMMON_PATH}/alfresco-transform-core-aio*.jar /opt/app.jar

RUN groupadd -g ${ALFRESCO_AIO_GROUP_ID} ${ALFRESCO_AIO_GROUP_NAME} && \
    useradd -u ${ALFRESCO_AIO_USER_ID} -g ${ALFRESCO_AIO_GROUP_NAME} ${ALFRESCO_AIO_USER_NAME} && \
    chgrp ${ALFRESCO_AIO_GROUP_NAME} /opt/app.jar

USER ${ALFRESCO_AIO_USER_NAME}

HEALTHCHECK --interval=20s --timeout=10s --retries=3 --start-period=30s \
  CMD curl -f http://localhost:8090/live || exit 1

COPY ${AIO_COMMON_PATH}/entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
