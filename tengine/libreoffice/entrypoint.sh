#!/bin/bash

# Check if the architecture is ARM64 (aarch64)
if [[ "$(uname -m)" != "x86_64" ]]; then
  export LIBREOFFICE_HOME=${LIBREOFFICE_HOME:=/usr/lib64/libreoffice}
fi

exec java $JAVA_OPTS $JAVA_OPTS_CONTAINER_FLAGS -jar /opt/app.jar
