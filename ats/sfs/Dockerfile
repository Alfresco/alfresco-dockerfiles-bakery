FROM java_base

EXPOSE 8099
ENV JAVA_OPTS_CONTAINER_FLAGS=-XX:MaxRAMPercentage=80

ARG ALFRESCO_SFS_GROUP_NAME
ARG ALFRESCO_SFS_GROUP_ID
ARG ALFRESCO_SFS_USER_NAME
ARG ALFRESCO_SFS_USER_ID

ADD alfresco-shared-file-store-controller*.jar /opt/app.jar

# Set default environment args
ARG FILE_STORE_DIR=/tmp/Alfresco

RUN mkdir -p ${FILE_STORE_DIR} && \
    groupadd -g ${ALFRESCO_SFS_GROUP_ID} ${ALFRESCO_SFS_GROUP_NAME} && \
    useradd -u ${ALFRESCO_SFS_USER_ID} -G ${ALFRESCO_SFS_GROUP_NAME} ${ALFRESCO_SFS_USER_NAME} && \
    chgrp -R ${ALFRESCO_SFS_GROUP_NAME} ${FILE_STORE_DIR} && \
    chmod g+rwx ${FILE_STORE_DIR} && \
    chgrp ${ALFRESCO_SFS_GROUP_NAME} /opt/app.jar

USER ${ALFRESCO_SFS_USER_NAME}

HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=1m \
  CMD curl -f http://localhost:8099/actuator/health || exit 1

COPY ats/sfs/entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
