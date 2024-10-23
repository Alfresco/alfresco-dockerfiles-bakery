#!/bin/bash

# URL of the compose file
COMPOSE_URL="https://raw.githubusercontent.com/Alfresco/acs-deployment/OPSEXP-2253/docker-compose/compose.yaml"

# Destination path for the downloaded file
DESTINATION_PATH="test/compose.yaml"

# Function to download the compose file using wget
download_compose_file_wget() {
  echo "Downloading compose file from ${COMPOSE_URL}..."
  wget -O "${DESTINATION_PATH}" "${COMPOSE_URL}"
  if [ $? -eq 0 ]; then
    echo "Compose file downloaded successfully to ${DESTINATION_PATH}"
  else
    echo "Failed to download compose file" >&2
    exit 1
  fi
}

# Download the compose file
download_compose_file_wget
