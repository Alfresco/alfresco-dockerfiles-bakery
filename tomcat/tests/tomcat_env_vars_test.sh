#!/bin/bash
# Test: Verify environment variable substitution works
IMAGE=$1

if ! out=$(docker run --rm -e TOMCAT_HTTP_PORT=9999 "$IMAGE" catalina.sh configtest 2>&1); then
  echo "Failed: catalina.sh configtest exited non-zero"
  echo "$out"
  exit 1
fi

# Check that the env var was applied
grep -q 'http-nio-9999' <<<"$out" || {
  echo "Failed: TOMCAT_HTTP_PORT env var not applied to server.xml"
  echo "$out"
  exit 1
}

# Check no unresolved placeholders
! grep -qE '\$\{|Exception' <<<"$out" || {
  echo "Failed: Unresolved placeholders or exceptions in output"
  echo "$out"
  exit 1
}

exit 0
