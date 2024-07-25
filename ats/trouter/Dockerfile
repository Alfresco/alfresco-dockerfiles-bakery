FROM java_base

EXPOSE 8095 8443

ARG ALFRESCO_TROUTER_GROUP_NAME
ARG ALFRESCO_TROUTER_GROUP_ID
ARG ALFRESCO_TROUTER_USER_NAME
ARG ALFRESCO_TROUTER_USER_ID

ADD ats/trouter/alfresco-transform-router*.jar /opt/app.jar

RUN groupadd -g ${ALFRESCO_TROUTER_GROUP_ID} ${ALFRESCO_TROUTER_GROUP_NAME} && \
    useradd -u ${ALFRESCO_TROUTER_USER_ID} -g ${ALFRESCO_TROUTER_GROUP_NAME} ${ALFRESCO_TROUTER_USER_NAME} && \
    chgrp ${ALFRESCO_TROUTER_GROUP_NAME} /opt/app.jar

USER ${ALFRESCO_TROUTER_USER_NAME}

HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=1m \
  CMD curl -f http://localhost:8095/actuator/health || exit 1

COPY ats/trouter/entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
