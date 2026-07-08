#!/bin/bash -e
set -o pipefail

TOMCAT_MAJOR="${1:?Usage: $0 <major_version>}"

curl -sf "https://downloads.apache.org/tomcat/tomcat-${TOMCAT_MAJOR}/" \
  | grep -oP 'href="v\K[0-9]+\.[0-9]+\.[0-9]+(?=/)' \
  | sort -V \
  | tail -1
