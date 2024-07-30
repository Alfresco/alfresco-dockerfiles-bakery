FROM java_base

EXPOSE 8090

ENV JAVA_OPTS_CONTAINER_FLAGS=-XX:MaxRAMPercentage=80
ENV LIBREOFFICE_COMMON_PATH=tengine/libreoffice

ARG ALFRESCO_LIBREOFFICE_GROUP_NAME
ARG ALFRESCO_LIBREOFFICE_GROUP_ID
ARG ALFRESCO_LIBREOFFICE_USER_NAME
ARG ALFRESCO_LIBREOFFICE_USER_ID

ADD ${LIBREOFFICE_COMMON_PATH}/alfresco-transform-libreoffice*.jar /usr/bin/app.jar
ADD ${LIBREOFFICE_COMMON_PATH}/libreoffice-dist*.gz /tmp/libreoffice-dist

RUN yum install -y cairo cups-libs libSM libGLU && \
    yum localinstall -y /tmp/libreoffice-dist/RPMS/*.rpm && \
    rm -rf /tmp/libreoffice-dist \
    yum clean all

RUN groupadd -g ${ALFRESCO_LIBREOFFICE_GROUP_ID} ${ALFRESCO_LIBREOFFICE_GROUP_NAME} && \
    useradd -u ${ALFRESCO_LIBREOFFICE_USER_ID} -g ${ALFRESCO_LIBREOFFICE_GROUP_NAME} ${ALFRESCO_LIBREOFFICE_USER_NAME} && \
    chgrp ${ALFRESCO_LIBREOFFICE_GROUP_NAME} /usr/bin/app.jar

USER ${ALFRESCO_LIBREOFFICE_USER_NAME}

HEALTHCHECK --interval=20s --timeout=10s --retries=3 --start-period=30s \
  CMD curl -f http://localhost:8090/live || exit 1

COPY ${LIBREOFFICE_COMMON_PATH}/entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
