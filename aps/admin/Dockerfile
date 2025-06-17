ARG DISTRIB_NAME=nodistro
ARG DISTRIB_MAJOR
ARG APS_ADMIN_GROUP_ID
ARG APS_ADMIN_USER_ID

FROM tomcat_base AS aps_admin_build

USER root

RUN set -x \
   && yum update -y \
   && yum install -y \
      unzip \
      wget \
      openssl \
      fontconfig dejavu-sans-fonts

ENV ACTIVITI_ADMIN_PROPS ${CATALINA_HOME}/lib/activiti-admin.properties

# Copy custom entrypoint and properties
COPY set-activiti-admin-config.sh entrypoint.sh get_from_s3.sh download_assets.sh /home/alfresco/
COPY docker-activiti-admin.properties ${ACTIVITI_ADMIN_PROPS}
COPY target/war ${CATALINA_HOME}/webapps/
RUN sed -i -e 's/<secure>.*<\/secure>//' ${CATALINA_HOME}/conf/web.xml && \
  /home/alfresco/download_assets.sh && \
  rm /home/alfresco/download_assets.sh

RUN yum remove wget -y && \
    yum autoremove -y && \
    yum clean all

RUN mkdir -p /usr/local/tomcat/work/Catalina/localhost/activiti-admin

RUN chown ${USERNAME}:${USERNAME} -R /usr/local/tomcat

# Docker layerization is procedural. This means that each directive is a layer, executed in the sequence in which it is presented.
# If a layer changes, it invalidates all subsequent layers.
# The EXPOSE, CMD and ENV layers are the ones least likely to change and they normally remain on top to reduce build time.
EXPOSE 8080

USER ${USERNAME}
CMD ["/home/alfresco/entrypoint.sh"]
