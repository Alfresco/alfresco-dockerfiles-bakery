FROM java_base

ENV JAVA_OPTS_CONTAINER_FLAGS=-XX:MaxRAMPercentage=80

EXPOSE 8090

ARG ALFRESCO_AIO_GROUP_NAME
ARG ALFRESCO_AIO_GROUP_ID
ARG ALFRESCO_AIO_USER_NAME
ARG ALFRESCO_AIO_USER_ID

RUN --mount=type=bind,source=/,target=/dist \
    mkdir /tmp/dist && \
    tar xzf /dist/libreoffice/*.gz -C /tmp/dist && \
    yum localinstall -y /tmp/dist/LibreOffice*/RPMS/*.rpm && \
    yum install -y cairo cups-libs libSM libGLU && \
    yum install -y /dist/imagemagick/imagemagick-distribution*-el9.rpm /dist/imagemagick/libs/imagemagick-distribution*-libs-el9.rpm && \
    tar xzf /dist/pdfrenderer/*.tgz -C /usr/bin && \
    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-${DISTRIB_MAJOR}.noarch.rpm && \
    yum -y install perl-Image-ExifTool && \
    rm -rf /tmp/dist && \
    yum clean all

ADD aio/alfresco-transform-core-aio*.jar /opt/app.jar

RUN groupadd -g ${ALFRESCO_AIO_GROUP_ID} ${ALFRESCO_AIO_GROUP_NAME} && \
    useradd -u ${ALFRESCO_AIO_USER_ID} -g ${ALFRESCO_AIO_GROUP_NAME} ${ALFRESCO_AIO_USER_NAME} && \
    chgrp ${ALFRESCO_AIO_GROUP_NAME} /opt/app.jar

USER ${ALFRESCO_AIO_USER_NAME}

HEALTHCHECK --interval=20s --timeout=10s --retries=3 --start-period=30s \
  CMD curl -f http://localhost:8090/live || exit 1

COPY aio/entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
