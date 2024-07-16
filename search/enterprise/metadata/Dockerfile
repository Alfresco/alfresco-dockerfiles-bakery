FROM quay.io/alfresco/alfresco-base-java:jre17-rockylinux9 AS build

ENV PORT=8080
EXPOSE 8080

ADD search/enterprise/metadata/*-app.jar /opt/app.jar

CMD ["java", "-jar", "/opt/app.jar"]
