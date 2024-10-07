FROM nginxinc/nginx-unprivileged:alpine3.20

ARG CONFIG_PATH=/etc/nginx/conf.d

USER root
RUN apk update && apk upgrade
COPY default.conf.template /etc/nginx/templates/
COPY app.config.json /usr/share/nginx/html/app.config.json
COPY ./*zip /tmp/

RUN unzip -o /tmp/*.zip -d /usr/share/nginx/html && \
    rm -rf /tmp/*zip

RUN chmod a+w -R ${CONFIG_PATH}

USER 101

# Nginx default settings
# -------------------------------
ENV SERVER_PORT=8080
ENV BASE_PATH=/
ENV NGINX_ENVSUBST_OUTPUT_DIR=${CONFIG_PATH}
