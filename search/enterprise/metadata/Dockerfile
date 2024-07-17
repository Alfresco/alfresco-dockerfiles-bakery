FROM quay.io/alfresco/alfresco-base-java:jre17-rockylinux9

ENV PORT=8080
EXPOSE 8080

ADD search/enterprise/metadata/*-app.jar /opt/app.jar

CMD java $JAVA_OPTS -jar /opt/app.jar
