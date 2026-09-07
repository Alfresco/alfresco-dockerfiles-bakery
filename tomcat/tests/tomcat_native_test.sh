#!/bin/bash
# Test: Verify Tomcat Native library is loaded
IMAGE=$1

docker run --rm "$IMAGE" catalina.sh configtest 2>&1 | grep -q "Loaded Apache Tomcat Native library"
