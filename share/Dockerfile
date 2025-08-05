ARG DISTRIB_NAME=nodistro
ARG DISTRIB_MAJOR
FROM tomcat_base AS share_build

USER root
EXPOSE 8000

RUN mkdir -p ${CATALINA_HOME}/shared/classes/alfresco/web-extension \
    ${CATALINA_HOME}/conf/Catalina/localhost

RUN yum install -y unzip

COPY entrypoint.sh ${CATALINA_HOME}/shared/classes/alfresco

ARG ALFRESCO_SHARE_ARTIFACT

COPY distribution/${ALFRESCO_SHARE_ARTIFACT}-*.zip /tmp/
COPY amps /tmp/amps

ENV DISTDIR="/tmp/distribution"

RUN unzip /tmp/*.zip -d ${DISTDIR}
RUN find ${DISTDIR} -type f -name share-config-custom.xml -exec cp {} ${CATALINA_HOME}/shared/classes/alfresco/web-extension/ \;
RUN if ls ${DISTDIR}/alfresco* > /dev/null 2>&1; then mv ${DISTDIR}/alfresco*/* ${DISTDIR}/; fi
RUN unzip ${DISTDIR}/web-server/webapps/share.war -d ${CATALINA_HOME}/webapps/share
RUN cp -r ${DISTDIR}/amps/ /tmp/amps/
RUN cp ${DISTDIR}/web-server/conf/Catalina/localhost/share.xml ${CATALINA_HOME}/conf/Catalina/localhost
RUN sed -i 's|../modules/share|modules/share|' ${CATALINA_HOME}/conf/Catalina/localhost/share.xml
RUN sed -i "s/shared.loader=/shared.loader=\${catalina.base}\/shared\/classes/" ${CATALINA_HOME}/conf/catalina.properties
RUN chmod +x ${CATALINA_HOME}/shared/classes/alfresco/entrypoint.sh

RUN java -jar ${DISTDIR}/bin/alfresco-mmt.jar install \
    /tmp/amps/ ${CATALINA_HOME}/webapps/share -directory -nobackup -force && \
    java -jar ${DISTDIR}/bin/alfresco-mmt.jar list ${CATALINA_HOME}/webapps/share

COPY simple_modules /tmp/simple_modules
RUN mkdir -m 750 -p ${CATALINA_HOME}/modules/share && \
    for jar in /tmp/simple_modules/*.jar; do \
      if [ -f "$jar" ]; then \
        echo "Adding ${jar##*/} simple module..."; \
        cp "$jar" ${CATALINA_HOME}/modules/share/; \
      else \
        echo "No simple module JARs found."; \
      fi; \
    done

FROM tomcat_base AS share-rhlike
ARG ALFRESCO_SHARE_USER_ID
ARG ALFRESCO_SHARE_GROUP_ID
ARG ALFRESCO_SHARE_GROUP_NAME
ARG ALFRESCO_SHARE_USER_NAME

COPY --chown=${ALFRESCO_SHARE_USER_ID}:${ALFRESCO_SHARE_GROUP_ID} --from=share_build ${CATALINA_HOME} ${CATALINA_HOME}

USER root
RUN groupadd -g ${ALFRESCO_SHARE_GROUP_ID} ${ALFRESCO_SHARE_GROUP_NAME} && \
    useradd -u ${ALFRESCO_SHARE_USER_ID} -g ${ALFRESCO_SHARE_GROUP_NAME} ${ALFRESCO_SHARE_USER_NAME} -G tomcat && \
    yum install -y xmlstarlet && \
    yum clean all && rm -rf /var/cache/yum

FROM share-rhlike AS share-rockylinux9

FROM share-${DISTRIB_NAME}${DISTRIB_MAJOR}
USER ${ALFRESCO_SHARE_USER_NAME}

ENTRYPOINT ["/usr/local/tomcat/shared/classes/alfresco/entrypoint.sh"]
