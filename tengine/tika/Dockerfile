FROM java_base

ENV TIKA_COMMON_PATH=tengine/tika
ENV JAVA_OPTS_CONTAINER_FLAGS=-XX:MaxRAMPercentage=80

EXPOSE 8090

ARG ALFRESCO_TIKA_GROUP_NAME
ARG ALFRESCO_TIKA_GROUP_ID
ARG ALFRESCO_TIKA_USER_NAME
ARG ALFRESCO_TIKA_USER_ID

RUN --mount=type=bind,source=${TIKA_COMMON_PATH},target=/dist \
    mkdir /tmp/dist && \
    tar xzf /dist/*.tgz -C /tmp/dist && \
    yum -y install perl perl-ExtUtils-MakeMaker make && \
    (cd /tmp/dist/Image-ExifTool-* && \
    perl Makefile.PL && \
    make && \
    make test && \
    make install) && \
    yum -y autoremove make && \    
    rm -rf /tmp/dist && \
    yum clean all

ADD ${TIKA_COMMON_PATH}/alfresco-transform-tika*.jar /usr/bin/app.jar

RUN groupadd -g ${ALFRESCO_TIKA_GROUP_ID} ${ALFRESCO_TIKA_GROUP_NAME} && \
    useradd -u ${ALFRESCO_TIKA_USER_ID} -g ${ALFRESCO_TIKA_GROUP_NAME} ${ALFRESCO_TIKA_USER_NAME} && \
    chgrp ${ALFRESCO_TIKA_GROUP_NAME} /usr/bin/app.jar

USER ${ALFRESCO_TIKA_USER_NAME}

HEALTHCHECK --interval=20s --timeout=10s --retries=3 --start-period=30s \
  CMD curl -f http://localhost:8090/live || exit 1

COPY ${TIKA_COMMON_PATH}/entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
