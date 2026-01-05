FROM busybox:stable@sha256:6b219909078e3fc93b81f83cb438bd7a5457984a01a478c76fe9777a8c67c39e AS unpack
WORKDIR /unpack
COPY alfresco-digital-workspace-*.zip .
RUN unzip alfresco-digital-workspace-*.zip && rm alfresco-digital-workspace-*.zip

FROM nginxinc/nginx-unprivileged:1-alpine@sha256:c2351965a68a252c32e0c03a5a7b2144087df078de199a3a67d35d41a41f4760

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
