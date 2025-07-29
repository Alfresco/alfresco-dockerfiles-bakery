FROM busybox:stable@sha256:31f3955f475e40c62c6d4209f09fd9738cf6cadfc0f4aa76ba2d4d86f061c5b5 AS unpack
WORKDIR /unpack
COPY alfresco-control-center-*.zip .
RUN unzip alfresco-control-center-*.zip && rm alfresco-control-center-*.zip

FROM nginxinc/nginx-unprivileged:1-alpine@sha256:43e46e21e93da1a7e6f3fb99595471c81426884e5a9beedb5b773b7a51d60e83

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
