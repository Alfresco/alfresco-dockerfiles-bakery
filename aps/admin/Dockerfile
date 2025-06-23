ARG DISTRIB_NAME=nodistro
ARG DISTRIB_MAJOR
ARG APS_ADMIN_GROUP_ID
ARG APS_ADMIN_USER_ID

FROM tomcat_base AS aps_admin_build

USER root
RUN yum install -y unzip

COPY distribution/activiti-admin-*.war /tmp/
ENV DISTDIR="/tmp/distribution"
ENV ACTIVITI_ADMIN_PROPS ${CATALINA_HOME}/lib/activiti-admin.properties

RUN unzip ${DISTDIR}/activiti-admin-*.war -d ${CATALINA_HOME}/webapps/activiti-admin
RUN sed -i -e 's/<secure>.*<\/secure>//' ${CATALINA_HOME}/conf/web.xml
RUN mkdir -p ${CATALINA_HOME}/work/Catalina/localhost/activiti-admin

COPY libs ${CATALINA_HOME}/lib/

FROM tomcat_base AS aps_admin_rhlike

ARG APS_ADMIN_GROUP_ID
ARG APS_ADMIN_USER_ID
ARG APS_ADMIN_GROUP_NAME
ARG APS_ADMIN_USER_NAME§

COPY --chown=${APS_ADMIN_GROUP_ID} --from=aps_admin_build ${CATALINA_HOME} ${CATALINA_HOME}

USER root
RUN groupadd -g ${APS_ADMIN_GROUP_ID} ${APS_ADMIN_GROUP_NAME} && \
    useradd -u ${APS_ADMIN_USER_ID} -g ${APS_ADMIN_GROUP_NAME} ${APS_ADMIN_USER_NAME} -G tomcat && \
    yum install -y openssl fontconfig dejavu-sans-fonts && \
    yum clean all && rm -rf /var/cache/yum

COPY entrypoint.sh /entrypoint.sh

FROM aps_admin_rhlike AS aps-admin-rockylinux9

FROM aps-admin-${DISTRIB_NAME}${DISTRIB_MAJOR}

EXPOSE 8080
VOLUME [ "${ACTIVITI_ADMIN_PROPS}" ]

USER ${APS_ADMIN_USER_NAME}
CMD ["/entrypoint.sh"]
