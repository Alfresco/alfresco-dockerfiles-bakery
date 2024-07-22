ARG DISTRIB_NAME
ARG DISTRIB_MAJOR

FROM tomcat_base AS repo_build

USER root
RUN yum install -y unzip

ADD alfresco-content-services-distribution-*.zip /tmp/

RUN unzip /tmp/alfresco-content-services-distribution-*.zip -d /tmp/distribution
RUN mkdir -p ${CATALINA_HOME}/shared/classes/alfresco/extension/keystore/ ${CATALINA_HOME}/alf_data
RUN unzip /tmp/distribution/web-server/webapps/alfresco.war -d ${CATALINA_HOME}/webapps/alfresco/
RUN cp -a /tmp/distribution/web-server/conf/* ${CATALINA_HOME}/conf/ && rm -f ${CATALINA_HOME}/conf/Catalina/localhost/share.xml
RUN cp -a /tmp/distribution/web-server/lib/* ${CATALINA_HOME}/lib/
RUN cp -a /tmp/distribution/licenses ${CATALINA_HOME}/
RUN cp -a /tmp/distribution/keystore/metadata-keystore/keystore* ${CATALINA_HOME}/shared/classes/alfresco/extension/keystore/
RUN sed -i 's|shared.loader=|shared.loader=${catalina.base}/shared/classes,${catalina.base}/shared/lib/*.jar|' ${CATALINA_HOME}/conf/catalina.properties
RUN sed -i 's|../modules/platform|modules/platform|' ${CATALINA_HOME}/conf/Catalina/localhost/alfresco.xml

FROM tomcat_base AS repo-rhlike

COPY --from=repo_build /usr/local/tomcat ${CATALINA_HOME}
USER root
RUN mkdir -p ${CATALINA_HOME}/modules/platform && \
  chown -R tomcat:tomcat ${CATALINA_HOME}/modules/platform && \
  yum install -y fontconfig dejavu-fonts-common fontpackages-filesystem freetype libpng dejavu-sans-fonts && \
  yum clean all && rm -rf /var/cache/yum

FROM repo-rhlike AS repo-rockylinux9

FROM repo-${DISTRIB_NAME}${DISTRIB_MAJOR}
USER tomcat

CMD ["catalina.sh", "run"]
