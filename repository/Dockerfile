ARG DISTRIB_NAME
ARG DISTRIB_MAJOR
ARG ALFRESCO_REPO_USER_ID
ARG ALFRESCO_REPO_GROUP_ID

FROM tomcat_base AS repo_build

USER root
RUN yum install -y unzip

ADD alfresco-content-services-distribution-*.zip /tmp/

RUN unzip /tmp/alfresco-content-services-distribution-*.zip -d /tmp/distribution
RUN mkdir -m 750 -p ${CATALINA_HOME}/shared/classes/alfresco/extension/keystore/ ${CATALINA_HOME}/alf_data
RUN unzip /tmp/distribution/web-server/webapps/alfresco.war -d ${CATALINA_HOME}/webapps/alfresco/
RUN cp -a /tmp/distribution/web-server/conf/* ${CATALINA_HOME}/conf/ && rm -f ${CATALINA_HOME}/conf/Catalina/localhost/share.xml
RUN cp -a /tmp/distribution/web-server/lib/* ${CATALINA_HOME}/lib/
RUN cp -a /tmp/distribution/licenses ${CATALINA_HOME}/
RUN cp -a /tmp/distribution/keystore/metadata-keystore/keystore* ${CATALINA_HOME}/shared/classes/alfresco/extension/keystore/
RUN chmod -R o= ${CATALINA_HOME}/
RUN sed -i 's|shared.loader=|shared.loader=${catalina.base}/shared/classes,${catalina.base}/shared/lib/*.jar|' \
  ${CATALINA_HOME}/conf/catalina.properties
RUN sed -i 's|../modules/platform|modules/platform|' ${CATALINA_HOME}/conf/Catalina/localhost/alfresco.xml
RUN sed -i \
  -re "s|(appender.rolling.fileName\=)(alfresco.log)|\1${CATALINA_HOME}/logs\/\2|" \
  -re "s|(appender.rolling.filePattern=)(alfresco.log.%d\{yyyy-MM-dd\})|\1${CATALINA_HOME}/logs\/\2|" \
  ${CATALINA_HOME}/webapps/alfresco/WEB-INF/classes/log4j2.properties

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
  yum install -y fontconfig dejavu-fonts-common fontpackages-filesystem freetype libpng dejavu-sans-fonts && \
  yum clean all && rm -rf /var/cache/yum

FROM repo-rhlike AS repo-rockylinux9

FROM repo-${DISTRIB_NAME}${DISTRIB_MAJOR}
USER ${ALFRESCO_REPO_USER_NAME}

CMD ["catalina.sh", "run"]
