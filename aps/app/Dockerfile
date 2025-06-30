ARG DISTRIB_NAME=nodistro
ARG DISTRIB_MAJOR
ARG APS_APP_GROUP_ID
ARG APS_APP_USER_ID

FROM tomcat_base AS aps_app_build

USER root
RUN yum install -y unzip

ENV DISTDIR="/tmp/distribution"

RUN mkdir -p ${DISTDIR}
COPY distribution/activiti-app-*.war ${DISTDIR}

RUN unzip ${DISTDIR}/activiti-app-*.war -d ${CATALINA_HOME}/webapps/activiti-app
RUN sed -i -e 's/<secure>.*<\/secure>//' ${CATALINA_HOME}/conf/web.xml
RUN mkdir -p ${CATALINA_HOME}/work/Catalina/localhost/activiti-app && \
    mkdir -p ${CATALINA_HOME}/conf/Catalina/localhost && \
    cp ${CATALINA_HOME}/webapps/activiti-app/META-INF/context.xml ${CATALINA_HOME}/conf/Catalina/localhost/activiti-app.xml

COPY libs ${CATALINA_HOME}/lib/

FROM tomcat_base AS aps_app_rhlike

ARG APS_APP_GROUP_ID
ARG APS_APP_USER_ID
ARG APS_APP_GROUP_NAME
ARG APS_APP_USER_NAME

ENV ACTIVITI_CONFIG_DIR=/
ENV ACTIVITI_APP_PROPS=${CATALINA_HOME}/lib/activiti-app.properties
ENV ACTIVITI_APP_PROPS_TEMPLATE=${ACTIVITI_CONFIG_DIR}/activiti-app.properties.template
ENV ACTIVITI_IDENTITY_SERVICE_PROPS=${CATALINA_HOME}/lib/activiti-identity-service.properties
ENV ACTIVITI_IDENTITY_SERVICE_PROPS_TEMPLATE=${ACTIVITI_CONFIG_DIR}/activiti-identity-service.properties.template
ENV ACTIVITI_APP_CONTENTSTORAGE_DIR=/usr/local/data

COPY --chown=${APS_APP_USER_ID}:${APS_APP_GROUP_ID} --from=aps_app_build ${CATALINA_HOME} ${CATALINA_HOME}
COPY --chown=${APS_APP_USER_ID}:${APS_APP_GROUP_ID} /configs/ ${ACTIVITI_CONFIG_DIR}

USER root
RUN groupadd -g ${APS_APP_GROUP_ID} ${APS_APP_GROUP_NAME} && \
    useradd -lu ${APS_APP_USER_ID} -g ${APS_APP_GROUP_NAME} ${APS_APP_USER_NAME} -G tomcat && \
    yum install -y openssl fontconfig dejavu-sans-fonts gettext && \
    yum clean all && rm -rf /var/cache/yum && \
    mkdir -p ${ACTIVITI_APP_CONTENTSTORAGE_DIR} && \
    chown -R ${APS_APP_USER_ID}:${APS_APP_GROUP_ID} ${ACTIVITI_APP_CONTENTSTORAGE_DIR}

FROM aps_app_rhlike AS aps-app-rockylinux9

FROM aps-app-${DISTRIB_NAME}${DISTRIB_MAJOR}

EXPOSE 8080

USER ${APS_APP_USER_NAME}
CMD ["/entrypoint.sh"]
