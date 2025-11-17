FROM busybox:stable@sha256:355b3a1bf5609da364166913878a8508d4ba30572d02020a97028c75477e24ff AS unpack
WORKDIR /unpack
COPY alfresco-digital-workspace-*.zip .
RUN unzip alfresco-digital-workspace-*.zip && rm alfresco-digital-workspace-*.zip

FROM nginxinc/nginx-unprivileged:1-alpine@sha256:9f89132a92072c24bbfb8bc3016d3f2912bcf6bde4bad50d7d2319f212c2765b

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
