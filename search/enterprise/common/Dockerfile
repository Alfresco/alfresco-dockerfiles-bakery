FROM java_base

ARG LIVEINDEXING
ENV PORT=8080
EXPOSE 8080

ADD search/enterprise/common/*${LIVEINDEXING}*-app.jar /opt/app.jar

HEALTHCHECK --interval=30s --timeout=3s --retries=3 --start-period=1m \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

COPY search/enterprise/common/entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
