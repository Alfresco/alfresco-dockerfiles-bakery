FROM tomcat_base AS repo_build

USER root
RUN yum install -y unzip

ADD alfresco-content-services-distribution-*.zip /tmp/

RUN unzip /tmp/alfresco-content-services-distribution-*.zip -d /tmp/distribution

RUN mkdir -p /usr/local/tomcat/shared/classes/alfresco/extension/keystore/

RUN unzip /tmp/distribution/web-server/webapps/alfresco.war -d /usr/local/tomcat/webapps/alfresco/
RUN cp -ra /tmp/distribution/web-server/conf/* /usr/local/tomcat/conf/ && rm -f /usr/local/tomcat/conf/Catalina/localhost/share.xml
RUN cp -ra /tmp/distribution/web-server/lib/* /usr/local/tomcat/lib/
RUN cp -ra /tmp/distribution/web-server/shared/* /usr/local/tomcat/shared/
RUN cp -ra /tmp/distribution/keystore/metadata-keystore/keystore* /usr/local/tomcat/shared/classes/alfresco/extension/keystore/

RUN sed -i 's|shared.loader=|shared.loader=${catalina.base}/shared/classes,${catalina.base}/shared/lib/*.jar|' /usr/local/tomcat/conf/catalina.properties
RUN sed -i 's|../modules/platform|modules/platform|' /usr/local/tomcat/conf/Catalina/localhost/alfresco.xml

FROM tomcat_base

RUN mkdir -p /usr/local/tomcat/modules/platform /usr/local/tomcat/modules/share

COPY --from=repo_build /usr/local/tomcat/conf /usr/local/tomcat/conf
COPY --from=repo_build /usr/local/tomcat/lib /usr/local/tomcat/lib
COPY --from=repo_build /usr/local/tomcat/shared /usr/local/tomcat/shared
COPY --from=repo_build /usr/local/tomcat/webapps /usr/local/tomcat/webapps

USER tomcat

CMD ["catalina.sh", "run"]
