FROM busybox:stable@sha256:7edf5efe6b86dbf01ccc3c76b32a37a8e23b84e6bad81ce8ae8c221fa456fda8 AS unpack
WORKDIR /unpack
COPY alfresco-control-center-*.zip .
RUN unzip alfresco-control-center-*.zip && rm alfresco-control-center-*.zip

FROM nginxinc/nginx-unprivileged:1-alpine@sha256:12b7750a5d621941f7ef8a3742f1c5850a69d5c4617dc53cd89000555cc8f7de

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
