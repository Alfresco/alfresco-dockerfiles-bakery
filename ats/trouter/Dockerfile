FROM java_base

EXPOSE 8095 8443

ARG GROUPNAME
ARG GROUPID
ARG ROUTERUSERNAME
ARG USERID

ADD ats/trouter/alfresco-transform-router*.jar /opt/app.jar

RUN groupadd -g ${GROUPID} ${GROUPNAME} && \
    useradd -u ${USERID} -G ${GROUPNAME} ${ROUTERUSERNAME} && \
    chgrp -R ${GROUPNAME} /opt/app.jar

USER ${ROUTERUSERNAME}

HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=1m \
  CMD curl -f http://localhost:8095/actuator/health || exit 1

COPY ats/trouter/entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
