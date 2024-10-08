FROM busybox AS unpack
WORKDIR /unpack
COPY ./*zip /
RUN unzip /*zip && rm /*zip

FROM nginxinc/nginx-unprivileged:alpine3.20

ARG CONFIG_PATH=/etc/nginx/conf.d

USER root
RUN apk update && apk upgrade
COPY default.conf.template /etc/nginx/templates/

COPY --from=unpack /unpack/ /usr/share/nginx/html/

RUN chmod a+w -R ${CONFIG_PATH}

USER 101

# Nginx default settings
# -------------------------------
ENV SERVER_PORT=8080
ENV BASE_PATH=/
ENV NGINX_ENVSUBST_OUTPUT_DIR=${CONFIG_PATH}
