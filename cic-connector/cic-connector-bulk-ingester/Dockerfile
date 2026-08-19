# Ignore linter checks enforcing Image Version as base is a transient build stage
# kics-scan disable=9efb0b2d-89c9-41a3-91ca-dcc0aec911fd
# hadolint ignore=DL3006
FROM java_base

EXPOSE 8080

ARG CIC_CONNECTOR_GROUP_NAME
ARG CIC_CONNECTOR_GROUP_ID
ARG CIC_CONNECTOR_USER_NAME
ARG CIC_CONNECTOR_USER_ID

COPY alfresco-cic-connector-bulk-ingester*.jar /opt/app.jar

RUN groupadd -g ${CIC_CONNECTOR_GROUP_ID} ${CIC_CONNECTOR_GROUP_NAME} && \
    useradd -lu ${CIC_CONNECTOR_USER_ID} -g ${CIC_CONNECTOR_GROUP_NAME} ${CIC_CONNECTOR_USER_NAME} && \
    chgrp ${CIC_CONNECTOR_GROUP_NAME} /opt/app.jar

HEALTHCHECK --interval=60s --timeout=10s --retries=3 --start-period=15s \
  CMD curl -f http://localhost:8080/actuator/health/readiness || exit 1

USER ${CIC_CONNECTOR_USER_NAME}

COPY entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
