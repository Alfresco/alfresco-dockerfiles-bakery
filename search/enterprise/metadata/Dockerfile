FROM quay.io/alfresco/alfresco-base-java:jre17-rockylinux9

ENV PORT=8080
EXPOSE 8080

ENV SPRING_ELASTICSEARCH_REST_URIS=http://elasticsearch:9200
ENV SPRING_ACTIVEMQ_BROKERURL=nio://activemq:61616

ADD search/enterprise/metadata/*-app.jar /opt/app.jar

COPY entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
