#!/bin/bash
# Test: Verify the RemoteIpValve internalProxies attribute references the
# correct environment variable for the Tomcat major version shipped in the
# image, and that the fallback regex env var is set for Tomcat 10.
IMAGE=$1

server_xml=$(docker run --rm "$IMAGE" cat conf/server.xml)

xpath='//Valve[@className="org.apache.catalina.valves.RemoteIpValve"]/@internalProxies'
internal_proxies=$(xmllint --xpath "$xpath" - <<<"$server_xml" 2>&1) || {
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
  expected_placeholder='${TOMCAT_REMOTE_IP_INTERNAL_PROXIES:-10/8,172.16/12,192.168/16,169.254/16,100.64/10,127/8,::1,fe80::/10,fc00::/7}'
else
  expected_placeholder='${TOMCAT_REMOTE_IP_INTERNAL_PROXIES_TOMCAT10_REGEX}'

  regex_env=$(docker run --rm "$IMAGE" printenv TOMCAT_REMOTE_IP_INTERNAL_PROXIES_TOMCAT10_REGEX)
  if [ -z "$regex_env" ]; then
    echo "Failed: TOMCAT_REMOTE_IP_INTERNAL_PROXIES_TOMCAT10_REGEX env var is not set in the image"
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
