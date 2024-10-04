FROM java_base

ARG LIVEINDEXING
ENV PORT=8080
EXPOSE 8080

COPY ${LIVEINDEXING}*-app.jar /opt/app.jar

HEALTHCHECK --interval=30s --timeout=3s --retries=3 --start-period=1m \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

COPY entrypoint.sh /entrypoint.sh

RUN groupadd -g ${ALFRESCO_LIVEINDEX_GROUP_ID} ${ALFRESCO_LIVEINDEX_GROUP_NAME} && \
    useradd -lu ${ALFRESCO_LIVEINDEX_USER_ID} -g ${ALFRESCO_LIVEINDEX_GROUP_NAME} ${ALFRESCO_LIVEINDEX_USER_NAME}

USER ${ALFRESCO_LIVEINDEX_USER_NAME}

CMD ["/entrypoint.sh"]
