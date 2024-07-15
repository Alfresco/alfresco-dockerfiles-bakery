FROM quay.io/alfresco/alfresco-base-java:jre17-rockylinux9 as BUILD

ENV PORT 8080
EXPOSE 8080

RUN yum install -y unzip

ADD *.jar /tmp/acrtifacts/
RUN unzip /tmp/acrtifacts/*-app.jar -d /opt/app.jar

WORKDIR /opt
ENTRYPOINT exec java $JAVA_OPTS -jar app.jar
