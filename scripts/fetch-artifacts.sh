#!/bin/bash -e
# Fetch artifact from Nexus which will be used to build the Docker image

REPO_ROOT="$(dirname $0)/.."
TEMP_DIR=$(mktemp -d)

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
    ARTIFACT_TMP_PATH="${TEMP_DIR}/${ARTIFACT_NAME}-${ARTIFACT_VERSION}${ARTIFACT_EXT}"
    ARTIFACT_CACHE_PATH="${REPO_ROOT}/artifacts_cache/${ARTIFACT_NAME}-${ARTIFACT_VERSION}${ARTIFACT_EXT}"
    ARTIFACT_FINAL_PATH="${ARTIFACT_PATH}/${ARTIFACT_NAME}-${ARTIFACT_VERSION}${ARTIFACT_EXT}"
    echo # newline for better readability
    if [ -f "${ARTIFACT_FINAL_PATH}" ]; then
      echo "Artifact $ARTIFACT_NAME-$ARTIFACT_VERSION already present, skipping..."
      continue
    fi
    if [ -f "${ARTIFACT_CACHE_PATH}" ]; then
      echo "Artifact $ARTIFACT_NAME-$ARTIFACT_VERSION already present in cache, copying..."
      cp "${ARTIFACT_CACHE_PATH}" "${ARTIFACT_FINAL_PATH}"
      continue
    fi
    echo "Downloading $ARTIFACT_GROUP:$ARTIFACT_NAME $ARTIFACT_VERSION from $ARTIFACT_BASEURL"
    if ! wget "${ARTIFACT_BASEURL}/${ARTIFACT_GROUP//\./\/}/${ARTIFACT_NAME}/${ARTIFACT_VERSION}/${ARTIFACT_NAME}-${ARTIFACT_VERSION}${ARTIFACT_EXT}" \
      -O "${ARTIFACT_TMP_PATH}" \
      --no-verbose; then
      rm -f "${ARTIFACT_TMP_PATH}" # wget leaves a 0 byte file if it fails
      echo "Skipping after wget failure..."
    else
      mv "${ARTIFACT_TMP_PATH}" "${ARTIFACT_CACHE_PATH}"
      cp "${ARTIFACT_CACHE_PATH}" "${ARTIFACT_FINAL_PATH}"
    fi
  done
}

TARGETS=$(find "${REPO_ROOT}" -regex "${REPO_ROOT}/${1:+$1/}.*" -name artifacts.json -mindepth 2 -print)

for i in $TARGETS ; do
  do_fetch_mvn $i
done
