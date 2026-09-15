FROM java_base

ENV JAVA_OPTS_CONTAINER_FLAGS=-XX:MaxRAMPercentage=80
ENV TIKA_DEP_RPM_URL=https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

EXPOSE 8090

ARG ALFRESCO_TIKA_GROUP_NAME
ARG ALFRESCO_TIKA_GROUP_ID
ARG ALFRESCO_TIKA_USER_NAME
ARG ALFRESCO_TIKA_USER_ID

# microdnf cannot install an rpm from a URL
RUN PKG_MGR=$(command -v dnf || command -v microdnf) && \
    rpm -Uvh --replacepkgs ${TIKA_DEP_RPM_URL} && \
    $PKG_MGR install -y perl-Image-ExifTool && \
    $PKG_MGR clean all && rm -rf /var/cache/dnf /var/cache/yum

ADD alfresco-transform-tika*.jar /opt/app.jar

RUN groupadd -g ${ALFRESCO_TIKA_GROUP_ID} ${ALFRESCO_TIKA_GROUP_NAME} && \
    useradd -u ${ALFRESCO_TIKA_USER_ID} -g ${ALFRESCO_TIKA_GROUP_NAME} ${ALFRESCO_TIKA_USER_NAME} && \
    chgrp ${ALFRESCO_TIKA_GROUP_NAME} /opt/app.jar

USER ${ALFRESCO_TIKA_USER_NAME}

HEALTHCHECK --interval=20s --timeout=10s --retries=3 --start-period=30s \
  CMD curl -f http://localhost:8090/live || exit 1

COPY entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
