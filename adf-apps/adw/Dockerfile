FROM busybox:stable@sha256:7edf5efe6b86dbf01ccc3c76b32a37a8e23b84e6bad81ce8ae8c221fa456fda8 AS unpack
WORKDIR /unpack
COPY alfresco-digital-workspace-*.zip .
RUN unzip alfresco-digital-workspace-*.zip && rm alfresco-digital-workspace-*.zip

FROM nginxinc/nginx-unprivileged:1-alpine@sha256:7ee77c5c1690b76bdb00d0555aa9ff251d7386dce48277a902f69ed478f7a3b0

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
