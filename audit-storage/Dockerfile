# Ignore linter checks enforcing Image Version as base is a trasient build stage
# kics-scan disable=9efb0b2d-89c9-41a3-91ca-dcc0aec911fd
# hadolint ignore=DL3006
FROM java_base

EXPOSE 8081

ARG ALFRESCO_AUDIT_STORAGE_GROUP_NAME
ARG ALFRESCO_AUDIT_STORAGE_GROUP_ID
ARG ALFRESCO_AUDIT_STORAGE_USER_NAME
ARG ALFRESCO_AUDIT_STORAGE_USER_ID

COPY alfresco-audit-storage-app*.jar /opt/app.jar

ENV AUDIT_ENTRYSTORAGE_OPENSEARCH_CONNECTOR_USERNAME=admin

RUN groupadd -g ${ALFRESCO_AUDIT_STORAGE_GROUP_ID} ${ALFRESCO_AUDIT_STORAGE_GROUP_NAME} && \
    useradd -lu ${ALFRESCO_AUDIT_STORAGE_USER_ID} -g ${ALFRESCO_AUDIT_STORAGE_GROUP_NAME} ${ALFRESCO_AUDIT_STORAGE_USER_NAME} && \
    chgrp ${ALFRESCO_AUDIT_STORAGE_GROUP_NAME} /opt/app.jar

HEALTHCHECK --interval=60s --timeout=10s --retries=3 --start-period=15s \
  CMD curl -f http://localhost:8081/actuator/health/readiness || exit 1

USER ${ALFRESCO_AUDIT_STORAGE_USER_NAME}

COPY entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
