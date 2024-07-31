FROM java_base

ENV JAVA_OPTS_CONTAINER_FLAGS=-XX:MaxRAMPercentage=80
ENV TIKA_COMMON_PATH=tengine/tika

EXPOSE 8090

ARG ALFRESCO_TIKA_GROUP_NAME
ARG ALFRESCO_TIKA_GROUP_ID
ARG ALFRESCO_TIKA_USER_NAME
ARG ALFRESCO_TIKA_USER_ID

COPY --from=exiftool_builder ${MAKE_PREFIX_PATH} /usr/bin/exiftool

RUN yum -y install perl-Image-ExifTool && \
    yum clean all

RUN groupadd -g ${ALFRESCO_TIKA_GROUP_ID} ${ALFRESCO_TIKA_GROUP_NAME} && \
    useradd -u ${ALFRESCO_TIKA_USER_ID} -g ${ALFRESCO_TIKA_GROUP_NAME} ${ALFRESCO_TIKA_USER_NAME} && \
    chgrp ${ALFRESCO_TIKA_GROUP_NAME} /opt/app.jar

USER ${ALFRESCO_TIKA_USER_NAME}

HEALTHCHECK --interval=20s --timeout=10s --retries=3 --start-period=30s \
  CMD curl -f http://localhost:8090/live || exit 1

COPY ${TIKA_COMMON_PATH}/entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
