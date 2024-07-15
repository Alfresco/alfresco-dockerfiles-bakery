FROM quay.io/alfresco/alfresco-base-java:jre17-rockylinux9 as BUILD

ENV PORT 8080
EXPOSE 8080

# debug current folder check whats in it
RUN ls -la

COPY *-app.jar /opt/app.jar

RUN chmod 755 /opt/app.jar

CMD ["java", "-jar", "/opt/app.jar"]
