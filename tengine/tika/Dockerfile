FROM java_base

ENV JAVA_OPTS_CONTAINER_FLAGS=-XX:MaxRAMPercentage=80
ENV TIKA_DEP_RPM_URL=https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

EXPOSE 8090

ARG ALFRESCO_TIKA_GROUP_NAME
ARG ALFRESCO_TIKA_GROUP_ID
ARG ALFRESCO_TIKA_USER_NAME
ARG ALFRESCO_TIKA_USER_ID

RUN yum install -y ${TIKA_DEP_RPM_URL} && \
    yum -y install perl-Image-ExifTool && \
    yum clean all

ADD alfresco-transform-tika*.jar /opt/app.jar

RUN groupadd -g ${ALFRESCO_TIKA_GROUP_ID} ${ALFRESCO_TIKA_GROUP_NAME} && \
    useradd -u ${ALFRESCO_TIKA_USER_ID} -g ${ALFRESCO_TIKA_GROUP_NAME} ${ALFRESCO_TIKA_USER_NAME} && \
    chgrp ${ALFRESCO_TIKA_GROUP_NAME} /opt/app.jar

USER ${ALFRESCO_TIKA_USER_NAME}

HEALTHCHECK --interval=20s --timeout=10s --retries=3 --start-period=30s \
  CMD curl -f http://localhost:8090/live || exit 1

COPY entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
