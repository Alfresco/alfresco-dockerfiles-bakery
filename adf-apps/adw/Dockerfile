FROM busybox:stable@sha256:303337d3d52898b33018796d760d3a01c2dcc87973dd66ec22fe78ae1e8429c9 AS unpack
WORKDIR /unpack
COPY alfresco-digital-workspace-*.zip .
RUN unzip alfresco-digital-workspace-*.zip && rm alfresco-digital-workspace-*.zip

FROM nginxinc/nginx-unprivileged:1-alpine@sha256:69e8821ff71771c12686bfd1a3f74b92c02f53ea422e1378d26fc7bb29044cf2

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
