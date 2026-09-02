#!/bin/bash
# Test: Verify the RemoteIpValve internalProxies attribute references the
# correct environment variable for the Tomcat major version shipped in the
# image, and that the fallback regex env var is set for Tomcat 10.
IMAGE=$1

internal_proxies=$(docker run --rm "$IMAGE" xmllint --xpath '//Valve[@className="org.apache.catalina.valves.RemoteIpValve"]/@internalProxies' conf/server.xml 2>&1) || {
  echo "Failed: could not extract internalProxies from server.xml"
  echo "$internal_proxies"
  exit 1
}

tomcat_major=$(docker run --rm "$IMAGE" catalina.sh version 2>&1 \
  | sed -n 's|.*Server number: *\([0-9]*\).*|\1|p')

if [ -z "$tomcat_major" ]; then
  echo "Failed: could not determine Tomcat major version"
  exit 1
fi

if [ "$tomcat_major" = "11" ]; then
  # shellcheck disable=SC2016  # the literal ${...} placeholder is the expected value
  expected_placeholder='${TOMCAT_REMOTE_IP_INTERNAL_PROXIES:-10/8,172.16/12,192.168/16,169.254/16,100.64/10,127/8,::1,fe80::/10,fc00::/7}'
else
  # shellcheck disable=SC2016  # the literal ${...} placeholder is the expected value
  expected_placeholder='${TOMCAT_REMOTE_IP_INTERNAL_PROXIES_TOMCAT10_REGEX}'

  # Compare against the Dockerfile value: an unquoted ENV strips the
  # backslashes, leaving a still-valid but wrong pattern
  expected_regex=$(sed -n 's/^ENV TOMCAT_REMOTE_IP_INTERNAL_PROXIES_TOMCAT10_REGEX="\(.*\)"$/\1/p' \
    "$(dirname "${BASH_SOURCE[0]}")/../Dockerfile")
  if [ -z "$expected_regex" ]; then
    echo "Failed: could not read the expected regex from tomcat/Dockerfile"
    exit 1
  fi

  regex_env=$(docker run --rm "$IMAGE" printenv TOMCAT_REMOTE_IP_INTERNAL_PROXIES_TOMCAT10_REGEX)
  if [ "$regex_env" != "$expected_regex" ]; then
    echo "Failed: TOMCAT_REMOTE_IP_INTERNAL_PROXIES_TOMCAT10_REGEX does not match the Dockerfile value"
    echo "Expected: $expected_regex"
    echo "Actual:   $regex_env"
    exit 1
  fi
fi

if [[ "$internal_proxies" != *"$expected_placeholder"* ]]; then
  echo "Failed: internalProxies does not reference the expected env var for Tomcat $tomcat_major"
  echo "Expected placeholder: $expected_placeholder"
  echo "Actual attribute: $internal_proxies"
  exit 1
fi

exit 0
