FROM tomcat_base

USER root
EXPOSE 8000

RUN mkdir -p ${CATALINA_HOME}/shared/classes/alfresco/web-extension \
    ${CATALINA_HOME}/amps_share \
    ${CATALINA_HOME}/webapps/share/ \
    ${CATALINA_HOME}/alfresco-mmt/ \
    /licenses

COPY entrypoint.sh ${CATALINA_HOME}/shared/classes/alfresco

ADD amps /tmp/amps
ADD distribution /tmp/
ENV DISTDIR="/tmp/distribution"

RUN yum install -y unzip xmlstarlet && \
    unzip /tmp/*.zip -d ${DISTDIR} &&\
    unzip ${DISTDIR}/alfresco*/web-server/webapps/share.war -d ${CATALINA_HOME}/webapps/share/ &&\
    cp ${DISTDIR}/alfresco*/bin/* ${CATALINA_HOME}/alfresco-mmt/ &&\
    cp -r ${DISTDIR}/alfresco*/amps ${CATALINA_HOME}/amps_share &&\
    cp /tmp/amps/*.amp ${CATALINA_HOME}/amps_share &&\
    cp ${DISTDIR}/alfresco*/web-extension-samples/custom-slingshot-application-context.xml.sample ${CATALINA_HOME}/shared/classes/alfresco/web-extension &&\
    cp ${DISTDIR}/alfresco*/web-extension-samples/smartfolders-amp-actions-config.xml ${CATALINA_HOME}/shared/classes/alfresco/web-extension &&\
    cp /tmp/share-config-custom.xml ${CATALINA_HOME}/shared/classes/alfresco/web-extension &&\
    rm -rf ${DISTDIR} /tmp &&\
    sed -i "s/shared.loader=/shared.loader=\${catalina.base}\/shared\/classes/" ${CATALINA_HOME}/conf/catalina.properties &&\
    chmod +x ${CATALINA_HOME}/shared/classes/alfresco/entrypoint.sh &&\
    yum clean all && rm -rf /var/cache/yum
    
RUN java -jar ${CATALINA_HOME}/alfresco-mmt/alfresco-mmt*.jar install \
              ${CATALINA_HOME}/amps_share ${CATALINA_HOME}/webapps/share -directory -nobackup -force

ENTRYPOINT ["/usr/local/tomcat/shared/classes/alfresco/entrypoint.sh"]
