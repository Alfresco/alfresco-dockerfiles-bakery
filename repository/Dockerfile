ARG DISTRIB_NAME
ARG DISTRIB_MAJOR
ARG ALFRESCO_REPO_USER_ID
ARG ALFRESCO_REPO_GROUP_ID

FROM tomcat_base AS repo_build

ARG ALFRESCO_REPO_ARTIFACT
ARG ALFRESCO_REPO_EDITION

USER root
RUN yum install -y unzip

COPY distribution/${ALFRESCO_REPO_ARTIFACT}-*.zip /tmp/
ENV DISTDIR="/tmp/distribution"

RUN unzip /tmp/*.zip -d ${DISTDIR}
RUN java -jar ${DISTDIR}/bin/alfresco-mmt.jar list ${DISTDIR}/web-server/webapps/alfresco.war
RUN mkdir -m 750 -p ${CATALINA_HOME}/shared/classes/alfresco/extension/keystore/
RUN mkdir -m 770 ${CATALINA_HOME}/alf_data/
RUN unzip ${DISTDIR}/web-server/webapps/alfresco.war -d ${CATALINA_HOME}/webapps/alfresco/
RUN cp -a ${DISTDIR}/web-server/conf/* ${CATALINA_HOME}/conf/ && rm -f ${CATALINA_HOME}/conf/Catalina/localhost/share.xml
RUN cp -a ${DISTDIR}/licenses ${CATALINA_HOME}/
RUN cp -a ${DISTDIR}/keystore/metadata-keystore/keystore* ${CATALINA_HOME}/shared/classes/alfresco/extension/keystore/
RUN chmod -R o-rwx ${CATALINA_HOME}/
RUN sed -i 's|shared.loader=|shared.loader=${catalina.base}/shared/classes,${catalina.base}/shared/lib/*.jar|' \
  ${CATALINA_HOME}/conf/catalina.properties
RUN sed -i 's|../modules/platform|modules/platform|' ${CATALINA_HOME}/conf/Catalina/localhost/alfresco.xml
RUN sed -i \
  -re "s|(appender.rolling.fileName\=)(alfresco.log)|\1${CATALINA_HOME}/logs\/\2|" \
  -re "s|(appender.rolling.filePattern=)(alfresco.log.%d\{yyyy-MM-dd\})|\1${CATALINA_HOME}/logs\/\2|" \
  ${CATALINA_HOME}/webapps/alfresco/WEB-INF/classes/log4j2.properties

COPY amps /tmp/amps
COPY amps_${ALFRESCO_REPO_EDITION} /tmp/amps
COPY libs ${CATALINA_HOME}/lib/
RUN if [ -f /tmp/amps/alfresco-aos-module-*.amp ]; then umask 0027; \
     unzip ${DISTDIR}/web-server/webapps/ROOT.war -d ${CATALINA_HOME}/webapps/ROOT/; \
     cp ${CATALINA_HOME}/webapps/ROOT/META-INF/context.xml ${CATALINA_HOME}/conf/Catalina/localhost/ROOT.xml; \
     unzip ${DISTDIR}/web-server/webapps/_vti_bin.war -d ${CATALINA_HOME}/webapps/_vti_bin/; \
   else echo "No AOS module found"; \
   fi
RUN java -jar ${DISTDIR}/bin/alfresco-mmt.jar install /tmp/amps/ ${CATALINA_HOME}/webapps/alfresco -nobackup -directory && \
    java -jar ${DISTDIR}/bin/alfresco-mmt.jar list ${CATALINA_HOME}/webapps/alfresco

FROM tomcat_base AS repo-rhlike
ARG ALFRESCO_REPO_USER_ID
ARG ALFRESCO_REPO_GROUP_ID
ARG ALFRESCO_REPO_GROUP_NAME
ARG ALFRESCO_REPO_USER_NAME

COPY --chown=:${ALFRESCO_REPO_GROUP_ID} --from=repo_build ${CATALINA_HOME} ${CATALINA_HOME}

USER root
RUN groupadd -g ${ALFRESCO_REPO_GROUP_ID} ${ALFRESCO_REPO_GROUP_NAME} && \
  useradd -u ${ALFRESCO_REPO_USER_ID} -g ${ALFRESCO_REPO_GROUP_NAME} ${ALFRESCO_REPO_USER_NAME} -G tomcat && \
  mkdir -m 750 -p ${CATALINA_HOME}/modules/platform && \
  chgrp -R ${ALFRESCO_REPO_GROUP_ID} ${CATALINA_HOME}/modules && \
  yum install -y fontconfig && \
  yum clean all && rm -rf /var/cache/yum

FROM repo-rhlike AS repo-rockylinux9

FROM repo-${DISTRIB_NAME}${DISTRIB_MAJOR}
USER ${ALFRESCO_REPO_USER_NAME}

CMD ["catalina.sh", "run"]
