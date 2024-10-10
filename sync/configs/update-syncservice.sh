#!/bin/bash

SYNC_SERVICE_FOLDER=${1}

# Change dsync user as root user 
sed -i 's/USER=\"dsync\"/USER=\"root\"/g' ${SYNC_SERVICE_FOLDER}/syncservice.sh

# Remove '&' sign from the end of the command in order to work with Centos image
sed -i 's/$SUPPRESS_OUTPUT_CMD &/$SUPPRESS_OUTPUT_CMD/g' ${SYNC_SERVICE_FOLDER}/syncservice.sh

# Enable logging of sync service output, which could be displayed using 'docker logs' command
SYNC_VERBOSE_OUTPUT=${SYNC_VERBOSE_OUTPUT:-'true'}

# Gets values if there are defined in the docker-compose or sets the default values
MAX_JAVA_HEAP_SIZE=${MAX_JAVA_HEAP_SIZE:-'2G'}
ENABLE_JMX_REMOTE=${ENABLE_JMX_REMOTE:-'false'}
JMX_REMOTE_PORT=${JMX_REMOTE_PORT:-50800}
JMX_RMI_HOSTNAME=${JMX_RMI_HOSTNAME:-}
JMX_REMOTE_RMI_PORT=${JMX_REMOTE_RMI_PORT:-50801}

ENABLE_JMX_REMOTE_AUTHENTICATION=${ENABLE_JMX_REMOTE_AUTHENTICATION:-'false'}
ENABLE_JMX_REMOTE_SSL=${ENABLE_JMX_REMOTE_SSL:-'false'}

SYNC_KEYSTORE_TYPE=${SYNC_KEYSTORE_TYPE:-PKCS12}
SYNC_KEYSTORE_PASSWORD=${SYNC_KEYSTORE_PASSWORD:-}

SYNC_TRUSTSTORE_TYPE=${SYNC_TRUSTSTORE_TYPE:-PKCS12}
SYNC_TRUSTSTORE_PASSWORD=${SYNC_TRUSTSTORE_PASSWORD:-}

# Subtitute new defined values
substitute(){
    sed -i 's/'$1'=.*/'$1'='$2'/' ${SYNC_SERVICE_FOLDER}/syncservice.sh

    # If JMX_REMOTE_AUTHENTICATION is enabled
    if [ ! -z $ENABLE_JMX_REMOTE_AUTHENTICATION ] && [ $ENABLE_JMX_REMOTE_AUTHENTICATION = true ]
    then
        sed -i 's/JMX_PASSWORD_FILE=.*/JMX_PASSWORD_FILE=jmx.password/' ${SYNC_SERVICE_FOLDER}/syncservice.sh
        sed -i 's/JMX_ACCESS_FILE=.*/JMX_ACCESS_FILE=jmx.access/' ${SYNC_SERVICE_FOLDER}/syncservice.sh
    fi

    # If JMX_REMOTE_SSL is enabled
    if [ ! -z $ENABLE_JMX_REMOTE_SSL ] && [ $ENABLE_JMX_REMOTE_SSL = true ]
    then
        sed -i 's/SYNC_KEYSTORE=.*/SYNC_KEYSTORE=sync.p12/' ${SYNC_SERVICE_FOLDER}/syncservice.sh
        sed -i 's/SYNC_TRUSTSTORE=.*/SYNC_TRUSTSTORE=sync.truststore/' ${SYNC_SERVICE_FOLDER}/syncservice.sh
    fi
}

substitute "MAX_JAVA_HEAP_SIZE" "$MAX_JAVA_HEAP_SIZE"
substitute "ENABLE_JMX_REMOTE" "$ENABLE_JMX_REMOTE"
substitute "JMX_REMOTE_PORT" "$JMX_REMOTE_PORT"
substitute "JMX_RMI_HOSTNAME" "$JMX_RMI_HOSTNAME"
substitute "JMX_REMOTE_RMI_PORT" "$JMX_REMOTE_RMI_PORT"
substitute "ENABLE_JMX_REMOTE_AUTHENTICATION" "$ENABLE_JMX_REMOTE_AUTHENTICATION"
substitute "ENABLE_JMX_REMOTE_SSL" "$ENABLE_JMX_REMOTE_SSL"
substitute "SYNC_KEYSTORE_TYPE" "$SYNC_KEYSTORE_TYPE"
substitute "SYNC_KEYSTORE_PASSWORD" "$SYNC_KEYSTORE_PASSWORD"
substitute "SYNC_TRUSTSTORE_TYPE" "$SYNC_TRUSTSTORE_TYPE"
substitute "SYNC_TRUSTSTORE_PASSWORD" "$SYNC_TRUSTSTORE_PASSWORD"
substitute "SYNC_VERBOSE_OUTPUT" "$SYNC_VERBOSE_OUTPUT"
