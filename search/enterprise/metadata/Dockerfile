FROM quay.io/alfresco/alfresco-base-java:jre17-rockylinux9 as BUILD
ENV PORT 8080
EXPOSE 8080
ARG VERSION 4.0.1
ARG ARTIFACT alfresco-elasticsearch-live-indexing-metadata
ARG NEXUS_URL https://nexus.alfresco.com/nexus/service/local/repositories/enterprise-releases/content/org/alfresco/${ARTIFACT}/${VERSION}/${ARTIFACT}-${VERSION}-app.jar

WORKDIR /opt
RUN curl -L -o alfresco-elasticsearch-live-indexing-metadata-app.jar ${NEXUS_URL}
ENTRYPOINT exec java $JAVA_OPTS -jar app.jar
