FROM java_base as libreoffice_base

ENV LIBREOFFICE_COMMON_PATH=tengine/libreoffice

RUN --mount=type=bind,source=${LIBREOFFICE_COMMON_PATH},target=/tmp \
    yum install -y cairo cups-libs libSM libGLU && \
    tar xzf /tmp/libreoffice-dist-linux.gz && \
    yum localinstall -y LibreOffice*/RPMS/*.rpm && \
    rm -rf /tmp/libreoffice-dist-linux.gz LibreOffice_*_Linux_x86-64_rpm && \
    yum clean all && \
    ln -s /tmp/alfresco-transform-libreoffice*.jar /usr/bin/app.jar

FROM libreoffice_base

EXPOSE 8090

ENV JAVA_OPTS_CONTAINER_FLAGS=-XX:MaxRAMPercentage=80

ARG ALFRESCO_LIBREOFFICE_GROUP_NAME
ARG ALFRESCO_LIBREOFFICE_GROUP_ID
ARG ALFRESCO_LIBREOFFICE_USER_NAME
ARG ALFRESCO_LIBREOFFICE_USER_ID

RUN groupadd -g ${ALFRESCO_LIBREOFFICE_GROUP_ID} ${ALFRESCO_LIBREOFFICE_GROUP_NAME} && \
    useradd -u ${ALFRESCO_LIBREOFFICE_USER_ID} -g ${ALFRESCO_LIBREOFFICE_GROUP_NAME} ${ALFRESCO_LIBREOFFICE_USER_NAME} && \
    chgrp ${ALFRESCO_LIBREOFFICE_GROUP_NAME} /usr/bin/app.jar

USER ${ALFRESCO_LIBREOFFICE_USER_NAME}

HEALTHCHECK --interval=20s --timeout=10s --retries=3 --start-period=30s \
  CMD curl -f http://localhost:8090/live || exit 1

COPY ${LIBREOFFICE_COMMON_PATH}/entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
