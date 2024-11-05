#!/bin/bash -e

usage() {
  echo "Usage: $0 <acs-deployment-version>" >&2
  exit 1
}

if [ "$#" -ne 1 ]; then
  usage
fi

ACS_DEPLOYMENT_VERSION="$1"
COMPOSE_FILES=(compose.yaml community-compose.yaml 7.4.N-compose.yaml)
DESTINATION_DIR="$(dirname "$0")/../test"

for COMPOSE_FILE in "${COMPOSE_FILES[@]}"; do
  COMPOSE_URL="https://raw.githubusercontent.com/Alfresco/acs-deployment/${ACS_DEPLOYMENT_VERSION}/docker-compose/${COMPOSE_FILE}"
  DESTINATION_PATH="${DESTINATION_DIR}/${COMPOSE_FILE}"
  echo "Downloading upstream acs-deployment compose file..."
  if wget -O "${DESTINATION_PATH}" --no-verbose "${COMPOSE_URL}"; then
    echo "Compose file downloaded successfully to ${DESTINATION_PATH}"
  else
    echo "Failed to download compose file" >&2
    rm -f "${DESTINATION_PATH}"
    exit 1
  fi
done
