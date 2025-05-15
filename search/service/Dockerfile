FROM java_base AS solr_build

ARG ALFRESCO_SOLR_DIST_DIR

USER root

COPY distribution /tmp/

RUN yum install -y xmlstarlet unzip && \
   unzip /tmp/*.zip -d $(dirname ${ALFRESCO_SOLR_DIST_DIR}) && \
   mkdir -p ${ALFRESCO_SOLR_DIST_DIR}/data && \
   mv ${ALFRESCO_SOLR_DIST_DIR}/solrhome/alfrescoModels ${ALFRESCO_SOLR_DIST_DIR}/data/ && \
   for i in ${ALFRESCO_SOLR_DIST_DIR}/solrhome/templates/*/conf/solrconfig.xml; do \
       xmlstarlet ed -L \
           -d '//comment()' \
           -s '/config/requestHandler[@name="/replication"]' -t elem -n lst \
           -a '/config/requestHandler[@name="/replication"]/lst[last()]' -t attr -n name -v '${solr.replication.master.role:notMaster}' \
           -s '/config/requestHandler[@name="/replication"]/lst[last()]' -t elem -n str -v '${solr.replication.replicate.after:commit,startup}' \
           -a '/config/requestHandler[@name="/replication"]/lst[last()]/str[last()]' -t attr -n name -v replicateAfter \
           -s '/config/requestHandler[@name="/replication"]/lst[last()]' -t elem -n str -v '${solr.replication.conf.files:schema.xml,stopwords.txt}' \
           -a '/config/requestHandler[@name="/replication"]/lst[last()]/str[last()]' -t attr -n name -v confFiles \
           -s '/config/requestHandler[@name="/replication"]' -t elem -n 'lst' \
           -a '/config/requestHandler[@name="/replication"]/lst[last()]' -t attr -n name -v '${solr.replication.slave.role:notSlave}' \
           -s '/config/requestHandler[@name="/replication"]/lst[last()]' -t elem -n str -v '${solr.replication.master.url:https://primary.domain.tld/solr/corename/replication}' \
           -a '/config/requestHandler[@name="/replication"]/lst[last()]/str[last()]' -t attr -n name -v masterUrl \
           -s '/config/requestHandler[@name="/replication"]/lst[last()]' -t elem -n str -v '${solr.replication.poll.interval:00:00:30}' \
           -a '/config/requestHandler[@name="/replication"]/lst[last()]/str[last()]' -t attr -n name -v pollInterval \
           $i; \
   done

FROM java_base AS solr-rhlike

ARG ALFRESCO_SOLR_USER_ID
ARG ALFRESCO_SOLR_USER_NAME
ARG ALFRESCO_SOLR_GROUP_ID
ARG ALFRESCO_SOLR_GROUP_NAME
ARG ALFRESCO_SOLR_DIST_DIR

ENV ALFRESCO_TEMPLATE=rerank

USER root

COPY --chown=:${ALFRESCO_SOLR_GROUP_ID} --from=solr_build ${ALFRESCO_SOLR_DIST_DIR} ${ALFRESCO_SOLR_DIST_DIR}
COPY entrypoint.sh /

WORKDIR ${ALFRESCO_SOLR_DIST_DIR}

RUN groupadd -g ${ALFRESCO_SOLR_GROUP_ID} ${ALFRESCO_SOLR_GROUP_NAME} && \
  useradd -u ${ALFRESCO_SOLR_USER_ID} -g ${ALFRESCO_SOLR_GROUP_NAME} ${ALFRESCO_SOLR_USER_NAME} && \
  yum install gettext -y && \
  yum clean all && \
  rm -rf /var/cache/yum && \
  chmod g+w -R {logs,data,solrhome} && \
  chmod +x /entrypoint.sh


VOLUME ["${ALFRESCO_SOLR_DIST_DIR}/data","${ALFRESCO_SOLR_DIST_DIR}/solrhome","${ALFRESCO_SOLR_DIST_DIR}/keystores"]

EXPOSE 8983

USER ${ALFRESCO_SOLR_USER_NAME}

CMD ["/entrypoint.sh"]
