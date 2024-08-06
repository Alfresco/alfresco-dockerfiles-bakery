FROM java_base

ENV JAVA_OPTS_CONTAINER_FLAGS=-XX:MaxRAMPercentage=80

EXPOSE 8090

ARG ALFRESCO_PDFRENDERER_GROUP_NAME
ARG ALFRESCO_PDFRENDERER_GROUP_ID
ARG ALFRESCO_PDFRENDERER_USER_NAME
ARG ALFRESCO_PDFRENDERER_USER_ID

RUN --mount=type=bind,source=/,target=/dist \
    tar xzf /dist/*.tgz -C /usr/bin && \
    yum clean all

ADD alfresco-transform-pdf-renderer*.jar /opt/app.jar

RUN groupadd -g ${ALFRESCO_PDFRENDERER_GROUP_ID} ${ALFRESCO_PDFRENDERER_GROUP_NAME} && \
    useradd -u ${ALFRESCO_PDFRENDERER_USER_ID} -g ${ALFRESCO_PDFRENDERER_GROUP_NAME} ${ALFRESCO_PDFRENDERER_USER_NAME} && \
    chgrp ${ALFRESCO_PDFRENDERER_GROUP_NAME} /opt/app.jar

USER ${ALFRESCO_PDFRENDERER_USER_NAME}

HEALTHCHECK --interval=20s --timeout=10s --retries=3 --start-period=30s \
  CMD curl -f http://localhost:8090/live || exit 1

COPY entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
