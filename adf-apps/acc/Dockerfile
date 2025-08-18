FROM busybox:stable@sha256:303337d3d52898b33018796d760d3a01c2dcc87973dd66ec22fe78ae1e8429c9 AS unpack
WORKDIR /unpack
COPY alfresco-control-center-*.zip .
RUN unzip alfresco-control-center-*.zip && rm alfresco-control-center-*.zip

FROM nginxinc/nginx-unprivileged:1-alpine@sha256:82dcf28da5a8cd97d43e8f8a64de766658b0c5fb9072368c5f0a9048c417a934

ARG CONFIG_PATH=/etc/nginx/conf.d

USER root
RUN apk update && \
    apk upgrade --no-cache && \
    rm -rf /var/cache/apk/*
COPY default.conf.template /etc/nginx/templates/

COPY --from=unpack /unpack/ /usr/share/nginx/html/

RUN chown -R 101:101 ${CONFIG_PATH}

USER 101

# Nginx default settings
# -------------------------------
ENV SERVER_PORT=8080
ENV BASE_PATH=/
ENV NGINX_ENVSUBST_OUTPUT_DIR=${CONFIG_PATH}
