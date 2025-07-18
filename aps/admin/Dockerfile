ARG DISTRIB_NAME=nodistro
ARG DISTRIB_MAJOR
ARG APS_ADMIN_GROUP_ID
ARG APS_ADMIN_USER_ID

FROM tomcat_base AS aps_admin_build

USER root
RUN yum install -y unzip

ENV DISTDIR="/tmp/distribution"

RUN mkdir -p ${DISTDIR}
COPY distribution/activiti-admin-*.war ${DISTDIR}

RUN unzip ${DISTDIR}/activiti-admin-*.war -d ${CATALINA_HOME}/webapps/activiti-admin
RUN sed -i -e 's/<secure>.*<\/secure>//' ${CATALINA_HOME}/conf/web.xml
RUN mkdir -p ${CATALINA_HOME}/work/Catalina/localhost/activiti-admin

COPY libs ${CATALINA_HOME}/lib/

FROM tomcat_base AS aps_admin_rhlike

ARG APS_ADMIN_GROUP_ID
ARG APS_ADMIN_USER_ID
ARG APS_ADMIN_GROUP_NAME
ARG APS_ADMIN_USER_NAME

ENV ACTIVITI_CONFIG_DIR=/
ENV ACTIVITI_ADMIN_PROPS=${CATALINA_HOME}/lib/activiti-admin.properties
ENV ACTIVITI_ADMIN_PROPS_TEMPLATE=${ACTIVITI_CONFIG_DIR}/activiti-admin.properties.template

COPY --chown=${APS_ADMIN_USER_ID}:${APS_ADMIN_GROUP_ID} --from=aps_admin_build ${CATALINA_HOME} ${CATALINA_HOME}
COPY --chown=${APS_ADMIN_USER_ID}:${APS_ADMIN_GROUP_ID} /configs/ ${ACTIVITI_CONFIG_DIR}

USER root
RUN groupadd -g ${APS_ADMIN_GROUP_ID} ${APS_ADMIN_GROUP_NAME} && \
    useradd -lu ${APS_ADMIN_USER_ID} -g ${APS_ADMIN_GROUP_NAME} ${APS_ADMIN_USER_NAME} -G tomcat && \
    yum install -y openssl fontconfig dejavu-sans-fonts gettext && \
    yum clean all && rm -rf /var/cache/yum

FROM aps_admin_rhlike AS aps-admin-rockylinux9

FROM aps-admin-${DISTRIB_NAME}${DISTRIB_MAJOR}

EXPOSE 8080

USER ${APS_ADMIN_USER_NAME}
CMD ["/entrypoint.sh"]
