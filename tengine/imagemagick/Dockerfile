FROM java_base

EXPOSE 8090

ENV JAVA_OPTS_CONTAINER_FLAGS=-XX:MaxRAMPercentage=80
ENV IMAGEMAGICK_DEP_RPM_URL=https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

ARG ALFRESCO_IMAGEMAGICK_GROUP_NAME
ARG ALFRESCO_IMAGEMAGICK_GROUP_ID
ARG ALFRESCO_IMAGEMAGICK_USER_NAME
ARG ALFRESCO_IMAGEMAGICK_USER_ID

ADD alfresco-transform-imagemagick*.jar /opt/app.jar
ADD imagemagick-distribution*-el9.rpm /tmp/imagemagick-distribution-el9.rpm
ADD libs/imagemagick-distribution*-libs-el9.rpm /tmp/imagemagick-distribution-libs-el9.rpm

RUN yum install -y $IMAGEMAGICK_DEP_RPM_URL && \
    yum install -y /tmp/imagemagick-distribution-el9.rpm /tmp/imagemagick-distribution-libs-el9.rpm; \
    yum clean all

RUN groupadd -g ${ALFRESCO_IMAGEMAGICK_GROUP_ID} ${ALFRESCO_IMAGEMAGICK_GROUP_NAME} && \
    useradd -u ${ALFRESCO_IMAGEMAGICK_USER_ID} -g ${ALFRESCO_IMAGEMAGICK_GROUP_NAME} ${ALFRESCO_IMAGEMAGICK_USER_NAME} && \
    chgrp ${ALFRESCO_IMAGEMAGICK_GROUP_NAME} /opt/app.jar

USER ${ALFRESCO_IMAGEMAGICK_USER_NAME}

HEALTHCHECK --interval=20s --timeout=10s --retries=3 --start-period=60s \
  CMD curl -f http://localhost:8090/live || exit 1

COPY entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
