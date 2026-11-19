#!/bin/bash
# Test: Verify the Base64 intrinsic is disabled (CVE-2026-114938 mitigation)
IMAGE=$1

if ! out=$(docker run --rm --entrypoint "" "$IMAGE" sh -c 'java -XX:+PrintFlagsFinal -version 2>&1 | grep UseBASE64Intrinsics'); then
  echo "Failed: could not read UseBASE64Intrinsics from the JVM"
  echo "$out"
  exit 1
fi

grep -qE 'UseBASE64Intrinsics.*= false' <<<"$out" || {
  echo "Failed: UseBASE64Intrinsics is not disabled"
  echo "$out"
  exit 1
}

exit 0
