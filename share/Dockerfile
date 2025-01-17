ARG DISTRIB_NAME
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
COPY distribution/share-config-custom.xml /tmp/
COPY amps /tmp/amps

ENV DISTDIR="/tmp/distribution"

RUN unzip /tmp/*.zip -d ${DISTDIR}
RUN if ls ${DISTDIR}/alfresco* > /dev/null 2>&1; then mv ${DISTDIR}/alfresco*/* ${DISTDIR}/; fi
RUN unzip ${DISTDIR}/web-server/webapps/share.war -d ${CATALINA_HOME}/webapps/share
RUN cp -r ${DISTDIR}/amps/ /tmp/amps/
RUN cp /tmp/share-config-custom.xml ${CATALINA_HOME}/shared/classes/alfresco/web-extension
RUN cp ${DISTDIR}/web-server/conf/Catalina/localhost/share.xml ${CATALINA_HOME}/conf/Catalina/localhost
RUN sed -i 's|../modules/share|modules/share|' ${CATALINA_HOME}/conf/Catalina/localhost/share.xml
RUN sed -i "s/shared.loader=/shared.loader=\${catalina.base}\/shared\/classes/" ${CATALINA_HOME}/conf/catalina.properties
RUN chmod +x ${CATALINA_HOME}/shared/classes/alfresco/entrypoint.sh

RUN java -jar ${DISTDIR}/bin/alfresco-mmt.jar install \
    /tmp/amps/ ${CATALINA_HOME}/webapps/share -directory -nobackup -force

COPY simple_modules /tmp/simple_modules
RUN mkdir -m 750 -p ${CATALINA_HOME}/modules/share && \
    for j in /tmp/simple_modules/jars/*.jar; do \
      if [ -f "$j" ]; then \
        j_name=${j##*/}; \
        echo "Adding $j_name simple module..."; \
        cp "$j" ${CATALINA_HOME}/modules/share/; \
      else \
        echo "No simple module JARs found."; \
      fi; \
    done && \
    if [ -f /tmp/simple_modules/config/properties/*/* ]; \
      then cp -a /tmp/simple_modules/config/properties/. ${CATALINA_HOME}/shared/classes/alfresco/module/; \
    else \
      echo "No simple modules properties found"; \
    fi && \
    if [ -f /tmp/simple_modules/config/resources/*/* ]; \
      then cp -a /tmp/simple_modules/config/resources/. ${CATALINA_HOME}/shared/classes/alfresco/META-INF/resources/; \
    else \
      echo "No simple modules resources found"; \
    fi

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
