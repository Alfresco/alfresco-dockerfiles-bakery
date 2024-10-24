#!/bin/bash

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <enterprise|community> <destination-filename> <acs-version>" >&2
  exit 1
fi

if [ "$1" = "enterprise" ]; then
  COMPOSE_FILE="compose.yaml"
else
  COMPOSE_FILE="community-compose.yaml"
fi

COMPOSE_URL="https://raw.githubusercontent.com/Alfresco/acs-deployment/$3/docker-compose/${COMPOSE_FILE}"

DESTINATION_PATH="$2"

echo "Downloading compose file from ${COMPOSE_URL}..."
wget -O "${DESTINATION_PATH}" "${COMPOSE_URL}"
if [ $? -eq 0 ]; then
  echo "Compose file downloaded successfully to ${DESTINATION_PATH}"
else
  echo "Failed to download compose file" >&2
  exit 1
fi
