ARG DISTRIB_NAME
ARG DISTRIB_MAJOR
FROM tomcat_base AS share_build

USER root
EXPOSE 8000

RUN mkdir -p ${CATALINA_HOME}/shared/classes/alfresco/web-extension \
    ${CATALINA_HOME}/conf/Catalina/localhost

COPY entrypoint.sh ${CATALINA_HOME}/shared/classes/alfresco

ADD amps /tmp/amps
ADD distribution /tmp/
ENV DISTDIR="/tmp/distribution"

RUN yum install -y unzip 
RUN unzip /tmp/*.zip -d ${DISTDIR} 
RUN unzip ${DISTDIR}/alfresco*/web-server/webapps/share.war -d ${CATALINA_HOME}/webapps/share/
RUN cp -r ${DISTDIR}/alfresco*/amps/ /tmp/amps/
RUN cp /tmp/share-config-custom.xml ${CATALINA_HOME}/shared/classes/alfresco/web-extension
RUN cp ${DISTDIR}/alfresco*/web-server/conf/Catalina/localhost/share.xml ${CATALINA_HOME}/conf/Catalina/localhost
RUN sed -i 's|../modules/share|modules/share|' ${CATALINA_HOME}/conf/Catalina/localhost/share.xml
RUN sed -i "s/shared.loader=/shared.loader=\${catalina.base}\/shared\/classes/" ${CATALINA_HOME}/conf/catalina.properties
RUN chmod +x ${CATALINA_HOME}/shared/classes/alfresco/entrypoint.sh
    
RUN java -jar ${DISTDIR}/alfresco*/bin/alfresco-mmt.jar install \
              /tmp/amps/ ${CATALINA_HOME}/webapps/share -directory -nobackup -force

FROM tomcat_base AS share-rhlike
ARG ALFRESCO_SHARE_USER_ID
ARG ALFRESCO_SHARE_GROUP_ID
ARG ALFRESCO_SHARE_GROUP_NAME
ARG ALFRESCO_SHARE_USER_NAME

COPY --chown=${ALFRESCO_SHARE_USER_ID}:${ALFRESCO_SHARE_GROUP_ID} --from=share_build ${CATALINA_HOME} ${CATALINA_HOME}

USER root
RUN groupadd -g ${ALFRESCO_SHARE_GROUP_ID} ${ALFRESCO_SHARE_GROUP_NAME} && \
    useradd -u ${ALFRESCO_SHARE_USER_ID} -g ${ALFRESCO_SHARE_GROUP_NAME} ${ALFRESCO_SHARE_USER_NAME} -G tomcat && \
    mkdir -m 750 -p ${CATALINA_HOME}/modules/share && \
    chgrp -R ${ALFRESCO_SHARE_GROUP_ID} ${CATALINA_HOME}/modules && \
    yum install -y xmlstarlet && \
    yum clean all && rm -rf /var/cache/yum

FROM share-rhlike AS share-rockylinux9

FROM share-${DISTRIB_NAME}${DISTRIB_MAJOR}
USER ${ALFRESCO_SHARE_USER_NAME}

ENTRYPOINT ["/usr/local/tomcat/shared/classes/alfresco/entrypoint.sh"]
