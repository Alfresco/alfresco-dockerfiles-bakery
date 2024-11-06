#!/bin/bash -e

# Determine the Tomcat version to use based on the acs version
# The acs version is passed as an argument to this script
# Example: ./scripts/determine-tomcat-version.sh 23

# Check if the acs version is passed as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <acs-version>"
  exit 1
fi

ACS_VERSION=$1
TOMCAT_VERSIONS_FILE="tomcat/tomcat_versions.yaml"

if [[ $ACS_VERSION == "23" ]]; then
  tomcat_field="tomcat10"
else
  tomcat_field="tomcat9"
fi

export TOMCAT_MAJOR=$(yq e ".${tomcat_field}.major" $TOMCAT_VERSIONS_FILE)
export TOMCAT_VERSION=$(yq e ".${tomcat_field}.version" $TOMCAT_VERSIONS_FILE)
export TOMCAT_SHA512=$(yq e ".${tomcat_field}.sha512" $TOMCAT_VERSIONS_FILE)
