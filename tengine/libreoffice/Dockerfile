FROM java_base as libreoffice_base

ENV LIBREOFFICE_COMMON_PATH=tengine/libreoffice

RUN --mount=type=bind,source=${LIBREOFFICE_COMMON_PATH},target=/tmp \
    yum install -y cairo cups-libs libSM libGLU && \
    if [ -f /tmp/libreoffice-dist-linux.gz ]; then \
        tar xzf /tmp/libreoffice-dist-linux.gz -C /tmp; \
    else \
        echo "File /tmp/libreoffice-dist-linux.gz not found"; \
        exit 1; \
    fi && \
    if ls /tmp/LibreOffice*/RPMS/*.rpm 1> /dev/null 2>&1; then \
        yum localinstall -y /tmp/LibreOffice*/RPMS/*.rpm; \
    else \
        echo "LibreOffice RPM files not found"; \
        exit 1; \
    fi && \
    rm -rf /tmp/libreoffice-dist-linux.gz /tmp/LibreOffice_*_Linux_x86-64_rpm && \
    yum clean all

FROM libreoffice_base

EXPOSE 8090

ENV JAVA_OPTS_CONTAINER_FLAGS=-XX:MaxRAMPercentage=80

ARG ALFRESCO_LIBREOFFICE_GROUP_NAME
ARG ALFRESCO_LIBREOFFICE_GROUP_ID
ARG ALFRESCO_LIBREOFFICE_USER_NAME
ARG ALFRESCO_LIBREOFFICE_USER_ID

ADD ${LIBREOFFICE_COMMON_PATH}/alfresco-transform-libreoffice*.jar /usr/bin/app.jar

RUN groupadd -g ${ALFRESCO_LIBREOFFICE_GROUP_ID} ${ALFRESCO_LIBREOFFICE_GROUP_NAME} && \
    useradd -u ${ALFRESCO_LIBREOFFICE_USER_ID} -g ${ALFRESCO_LIBREOFFICE_GROUP_NAME} ${ALFRESCO_LIBREOFFICE_USER_NAME} && \
    chgrp ${ALFRESCO_LIBREOFFICE_GROUP_NAME} /usr/bin/app.jar

USER ${ALFRESCO_LIBREOFFICE_USER_NAME}

HEALTHCHECK --interval=20s --timeout=10s --retries=3 --start-period=30s \
  CMD curl -f http://localhost:8090/live || exit 1

COPY ${LIBREOFFICE_COMMON_PATH}/entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
