FROM java_base

EXPOSE 8090

ENV JAVA_OPTS_CONTAINER_FLAGS=-XX:MaxRAMPercentage=80
ENV IMAGEMAGICK_DEP_RPM_URL=https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
ENV IMAGEMAGICK_RPM_PATH=tengine/imagemagick/imagemagick-distribution

ARG ALFRESCO_IMAGEMAGICK_GROUP_NAME
ARG ALFRESCO_IMAGEMAGICK_GROUP_ID
ARG ALFRESCO_IMAGEMAGICK_USER_NAME
ARG ALFRESCO_IMAGEMAGICK_USER_ID

ADD tengine/imagemagick/alfresco-transform-imagemagick*.jar /usr/bin/app.jar

RUN yum install -y $IMAGEMAGICK_DEP_RPM_URL && \
    yum install -y ${IMAGEMAGICK_RPM_PATH}*-el8.rpm ${IMAGEMAGICK_RPM_PATH}*-el8-libs.rpm; \
    yum clean all

RUN groupadd -g ${ALFRESCO_IMAGEMAGICK_GROUP_ID} ${ALFRESCO_IMAGEMAGICK_GROUP_NAME} && \
    useradd -u ${ALFRESCO_IMAGEMAGICK_USER_ID} -G ${ALFRESCO_IMAGEMAGICK_GROUP_NAME} ${ALFRESCO_IMAGEMAGICK_USER_NAME} && \
    chgrp ${ALFRESCO_IMAGEMAGICK_GROUP_NAME} /usr/bin/app.jar

USER ${ALFRESCO_IMAGEMAGICK_USER_NAME}

HEALTHCHECK --interval=20s --timeout=10s --retries=3 --start-period=30s \
  CMD curl -f http://localhost:8090/live || exit 1

COPY tengine/imagemagick/entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
