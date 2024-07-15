#!/bin/bash -e
# Fetch artifact from Nexus which will be used to build the Docker image

ARTIFACT_NAME=$1
DEFAULT_ARTIFACT_NAME=alfresco-content-services-distribution

ARTIFACT_VERSION=$2
DEFAULT_ARTIFACT_VERSION=23.2.1

EXTENSION=$3
DEFAULT_EXTENSION=.zip

GROUP_ID=$4
DEFAULT_GROUP_ID=org.alfresco

PATH_FOR_ARTIFACT=$5
DEFAULT_PATH_FOR_ARTIFACT=./

if [ -z "$ARTIFACT_NAME" ]; then
    ARTIFACT_NAME=$DEFAULT_ARTIFACT_NAME
fi

if [ -z "$ARTIFACT_VERSION" ]; then
    ARTIFACT_VERSION=$DEFAULT_ARTIFACT_VERSION
fi

if [ -z "$EXTENSION" ]; then
    EXTENSION=$DEFAULT_EXTENSION
fi

if [ -z "$GROUP_ID" ]; then
    GROUP_ID=$DEFAULT_GROUP_ID
fi

if [ -z "$PATH_FOR_ARTIFACT" ]; then
    PATH_FOR_ARTIFACT=$DEFAULT_PATH_FOR_ARTIFACT
fi

GROUP_ID_AS_PATH=$(echo "$GROUP_ID" | tr . /)


echo "Downloading $GROUP_ID:$ARTIFACT_NAME $ARTIFACT_VERSION from Nexus"
wget "https://nexus.alfresco.com/nexus/service/local/repositories/enterprise-releases/content/$GROUP_ID_AS_PATH/$ARTIFACT_NAME/${ARTIFACT_VERSION}/$ARTIFACT_NAME-${ARTIFACT_VERSION}${EXTENSION}"
 
