#!/bin/bash -e
# Fetch artifact from Nexus which will be used to build the Docker image

REPO_ROOT=$(dirname $0)

ACS_VERSION=${ACS_VERSION:=23.2.2}
INDEX_KEY=${ACS_VERSION%%.*}

cd ${REPO_ROOT}/..

for i in $(find . -name artifacts.json -mindepth 2); do
  for j in $(jq -r ".artifacts.acs${INDEX_KEY} | keys | .[]" $i); do
    ARTIFACT_REPO=$(jq -r ".artifacts.acs${INDEX_KEY}[$j].repository" $i)
    ARTIFACT_NAME=$(jq -r ".artifacts.acs${INDEX_KEY}[$j].name" $i)
    ARTIFACT_VERSION=$(jq -r ".artifacts.acs${INDEX_KEY}[$j].version" $i)
    ARTIFACT_EXT=$(jq -r ".artifacts.acs${INDEX_KEY}[$j].classifier" $i)
    ARTIFACT_GROUP=$(jq -r ".artifacts.acs${INDEX_KEY}[$j].group" $i)
    ARTIFACT_PATH=$(jq -r ".artifacts.acs${INDEX_KEY}[$j].path" $i)
    ARTIFACT_BASEURL="https://nexus.alfresco.com/nexus/repository/${ARTIFACT_REPO}"
    echo "Downloading $ARTIFACT_GROUP:$ARTIFACT_NAME $ARTIFACT_VERSION from $ARTIFACT_BASEURL"
    wget "${ARTIFACT_BASEURL}/${ARTIFACT_GROUP//\./\/}/${ARTIFACT_NAME}/${ARTIFACT_VERSION}/${ARTIFACT_NAME}-${ARTIFACT_VERSION}${ARTIFACT_EXT}" \
      -O ${ARTIFACT_PATH}/${ARTIFACT_NAME}-${ARTIFACT_VERSION}${ARTIFACT_EXT}
  done
done
