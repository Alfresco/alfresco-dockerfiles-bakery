#!/bin/bash -e

usage() {
  echo "Usage: $0 <acs-deployment-version>" >&2
  exit 1
}

if [ "$#" -ne 1 ]; then
  usage
fi

ACS_DEPLOYMENT_VERSION="$1"
HELM_FILES=(helm/alfresco-content-services/community_values.yaml test/enterprise-integration-test-values.yaml test/community-integration-test-values.yaml)
DESTINATION_DIR="$(dirname "$0")/../test/helm"

for HELM_FILE in "${HELM_FILES[@]}"; do
  FILE_URL="https://raw.githubusercontent.com/Alfresco/acs-deployment/${ACS_DEPLOYMENT_VERSION}/${HELM_FILE}"
  DESTINATION_PATH="${DESTINATION_DIR}/${HELM_FILE##*/}"
  echo "Downloading upstream acs-deployment ${HELM_FILE} file..."
  if wget -O "${DESTINATION_PATH}" --no-verbose "${FILE_URL}"; then
    echo "File downloaded successfully to ${DESTINATION_PATH}"
  else
    echo "Failed to download file" >&2
    rm -f "${DESTINATION_PATH}"
    exit 1
  fi
done
