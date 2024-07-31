FROM java_base

ENV MISC_COMMON_PATH=tengine/misc
ENV JAVA_OPTS_CONTAINER_FLAGS=-XX:MaxRAMPercentage=80

EXPOSE 8090

ARG ALFRESCO_MISC_GROUP_NAME
ARG ALFRESCO_MISC_GROUP_ID
ARG ALFRESCO_MISC_USER_NAME
ARG ALFRESCO_MISC_USER_ID

ADD ${MISC_COMMON_PATH}/alfresco-transform-misc*.jar /opt/app.jar

RUN groupadd -g ${ALFRESCO_MISC_GROUP_ID} ${ALFRESCO_MISC_GROUP_NAME} && \
    useradd -u ${ALFRESCO_MISC_USER_ID} -g ${ALFRESCO_MISC_GROUP_NAME} ${ALFRESCO_MISC_USER_NAME} && \
    chgrp ${ALFRESCO_MISC_GROUP_NAME} /opt/app.jar

USER ${ALFRESCO_MISC_USER_NAME}

HEALTHCHECK --interval=20s --timeout=10s --retries=3 --start-period=30s \
  CMD curl -f http://localhost:8090/live || exit 1

COPY ${MISC_COMMON_PATH}/entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
