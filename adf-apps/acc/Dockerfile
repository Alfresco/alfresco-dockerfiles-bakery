FROM busybox:stable@sha256:6b219909078e3fc93b81f83cb438bd7a5457984a01a478c76fe9777a8c67c39e AS unpack
WORKDIR /unpack
COPY alfresco-control-center-*.zip .
RUN unzip alfresco-control-center-*.zip && rm alfresco-control-center-*.zip

FROM nginxinc/nginx-unprivileged:1-alpine@sha256:11cab1801e5b195e6e6aab60b4dce008081bb096ab919233b75265b6b3d8ea47

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
