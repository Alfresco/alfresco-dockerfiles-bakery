FROM quay.io/alfresco/alfresco-base-java:jre17-rockylinux9 as BUILD

ENV PORT 8080
EXPOSE 8080

ADD *-app.jar /opt/app.jar

WORKDIR /opt
ENTRYPOINT exec java $JAVA_OPTS -jar app.jar
