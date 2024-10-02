#!/bin/sh
#
# This script is the entrypoint for the Docker container. It is responsible for
# setting the environment variables and starting the application.

# Set the environment variables

export SOLR_OPTS_TPL='$SOLR_OPTS'

CORE_TPL="solrhome/templates/${ALFRESCO_TEMPLATE}/conf/solrcore.properties"

while read var val; do VAR=${var^^}
    eval $(echo export "${VAR//./_}=\${${VAR//./_}:-$val}")
    SOLR_OPTS_TPL+=" -D${var}=\${${VAR//./_}}"
done < <(grep -Ev '^\s*(#|alfresco\.(cron|secureComms)\s*=|$)' "$CORE_TPL" | sed -re 's/^\s*(.*)=/\1 /')

export SOLR_OPTS=$(echo $SOLR_OPTS_TPL | envsubst)

# Alfresco/Solr shared secret
if [ "$ALFRESCO_SECURECOMMS" == "secret" ]; then echo "Alfresco Search service with shared secret AUTH"
    if [ -z "$ALFRESCO_SECURECOMMS_SECRET" ]; then
        echo "ALFRESCO_SECURECOMMS_SECRET is not set. Exiting..."
        exit 1
    fi
    export SOLR_OPTS="$SOLR_OPTS -Dalfresco.secureComms.secret=$ALFRESCO_SECURECOMMS_SECRET -Dalfresco.secureComms=secret"
fi

# Solr replication
if [ "$SOLR_REPLICATION_MASTER" == "true" ]; then echo "Alfresco Search service will run as a Master replica"
    export SOLR_OPTS="$SOLR_OPTS -Dsolr.replication.master.role=master"
fi
if [ "$SOLR_REPLICATION_SLAVE" == "true" ]; then echo "Alfresco Search service will run as a Slave replica"
    if [ -z "$SOLR_REPLICATION_MASTER_URL" ]; then
        echo "SOLR_REPLICATION_MASTER_URL for the Slave is not set. Exiting..."
        exit 1
    fi
    export ENABLE_ALFRESCO_TRACKING=false
    export SOLR_OPTS="$SOLR_OPTS -Dsolr.replication.slave.role=slave -Dsolr.replication.master.url=$SOLR_REPLICATION_MASTER_URL"
fi

# Index Lock config
if [ -n "$SOLR_DATA_DIR_ROOT" ]; then echo "Alfresco Search service will run with data directory $SOLR_DATA_DIR_ROOT"
    export SOLR_OPTS="$SOLR_OPTS -Ddata.dir.root=$SOLR_DATA_DIR_ROOT"
fi
if [ -n "$SOLR_DIRECTORY_FACTORY" ]; then echo -n "Running Indexes using ${SOLR_DIRECTORY_FACTORY:-default} directory factory with locking ${SOLR_LOCK_TYPE:-native}"
    export SOLR_OPTS="$SOLR_OPTS -Dsolr.lock.type=${SOLR_LOCK_TYPE:-native} -Dsolr.directoryFactory=${SOLR_DIRECTORY_FACTORY}"
fi

exec ./solr/bin/solr start -f
