FROM quay.io/alfresco/alfresco-base-java:jre17-rockylinux9 as BUILD

ENV PORT 8080
EXPOSE 8080

ADD alfresco-elasticsearch-live-indexing-metadata-4.0.1-app.jar /opt/app.jar

CMD ["java", "-jar", "/opt/app.jar"]
