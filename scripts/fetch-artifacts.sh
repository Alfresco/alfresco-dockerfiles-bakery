#!/bin/bash -e
# Fetch artifact from Nexus which will be used to build the Docker image

REPO_ROOT=$(dirname $0)

ACS_VERSION=${ACS_VERSION:=23.2.2}
INDEX_KEY=${ACS_VERSION%%.*}

do_fetch_mvn() {
  for i in $(jq -r ".artifacts.acs${INDEX_KEY} | keys | .[]" $1); do
    ARTIFACT_REPO=$(jq -r ".artifacts.acs${INDEX_KEY}[$i].repository" $1)
    ARTIFACT_NAME=$(jq -r ".artifacts.acs${INDEX_KEY}[$i].name" $1)
    ARTIFACT_VERSION=$(jq -r ".artifacts.acs${INDEX_KEY}[$i].version" $1)
    ARTIFACT_EXT=$(jq -r ".artifacts.acs${INDEX_KEY}[$i].classifier" $1)
    ARTIFACT_GROUP=$(jq -r ".artifacts.acs${INDEX_KEY}[$i].group" $1)
    ARTIFACT_PATH=$(jq -r ".artifacts.acs${INDEX_KEY}[$i].path" $1)
    ARTIFACT_BASEURL="https://nexus.alfresco.com/nexus/repository/${ARTIFACT_REPO}"
    ARTIFACT_FINAL_PATH="${ARTIFACT_PATH}/${ARTIFACT_NAME}-${ARTIFACT_VERSION}${ARTIFACT_EXT}"
    if [ -f "${ARTIFACT_FINAL_PATH}" ]; then
      echo "Artifact $ARTIFACT_NAME-$ARTIFACT_VERSION already downloaded, skipping..."
      continue
    fi
    echo "Downloading $ARTIFACT_GROUP:$ARTIFACT_NAME $ARTIFACT_VERSION from $ARTIFACT_BASEURL"
    wget "${ARTIFACT_BASEURL}/${ARTIFACT_GROUP//\./\/}/${ARTIFACT_NAME}/${ARTIFACT_VERSION}/${ARTIFACT_NAME}-${ARTIFACT_VERSION}${ARTIFACT_EXT}" \
      -O "${ARTIFACT_FINAL_PATH}" \
      --no-verbose
  done
}

cd ${REPO_ROOT}/..

TARGETS=$(find . -regex "./${1:+$1/}.*" -name artifacts.json -mindepth 2 -print)

for i in $TARGETS ; do
  do_fetch_mvn $i
done
