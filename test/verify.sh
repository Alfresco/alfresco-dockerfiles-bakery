#!/bin/bash
# verify.sh - Auto-discover and run image tests
# Finds */tests/*_test.sh files and runs them against appropriate images
# based on docker-bake.hcl inheritance relationships

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HCL_FILE="$REPO_ROOT/docker-bake.hcl"

REGISTRY="${REGISTRY:-localhost}"
REGISTRY_NAMESPACE="${REGISTRY_NAMESPACE:-alfresco}"

# Initialize artifact versions for tag resolution
export ARTIFACT_VERSIONS=$(python3 "$REPO_ROOT/scripts/print_artifact_versions.py")

# ============================================================================
# Helper: Find the bake target that uses a given folder as its main context
# ============================================================================
find_target_for_context() {
  local context="$1"
  hcl2json "$HCL_FILE" 2>/dev/null | jq -r "
    .target | to_entries[] |
    select(.value[0].context == \"$context\") |
    .key
  "
}

# ============================================================================
# Helper: Get the first final target that inherits from a given target
# ============================================================================
find_final_target_inheriting_from() {
  local parent_target="$1"
  hcl2json "$HCL_FILE" 2>/dev/null | jq -r "
    ([
      .target | to_entries[] |
      select(
        (.value[0].inherits | index(\"$parent_target\")) or
        (.value[0].contexts | has(\"$parent_target\"))
      ) |
      select(
        (.value[0].output[0] // \"type=docker\") | contains(\"cacheonly\") | not
      ) |
      .key
    ] | first) // empty
  "
}

# ============================================================================
# Helper: Check if a target is final (not cache-only)
# ============================================================================
is_target_final() {
  local target="$1"
  hcl2json "$HCL_FILE" 2>/dev/null | jq -e "
    .target[\"$target\"][0].output[0] // \"type=docker\" | contains(\"cacheonly\") | not
  " >/dev/null 2>&1
}

# ============================================================================
# Helper: Get the full tag for a target (with registry, namespace, and version)
# ============================================================================
get_image_tag_for_target() {
  local target="$1"
  local image_name version

  # Extract image name from bake target tag template
  image_name=$(hcl2json "$HCL_FILE" 2>/dev/null | jq -r "
    .target[\"$target\"][0].tags[0] | split(\"/\")[-1] | split(\":\")[0]
  ")

  # Look up version from artifact versions
  version=$(echo "$ARTIFACT_VERSIONS" | jq -r ".\"$image_name\" // \"latest\"")

  # Construct full tag: registry/namespace/image:version
  echo "$REGISTRY/$REGISTRY_NAMESPACE/$image_name:$version"
}

# ============================================================================
# Validation
# ============================================================================
if [ ! -f "$HCL_FILE" ]; then
  echo "Error: $HCL_FILE not found" >&2
  exit 1
fi

if ! command -v hcl2json &>/dev/null; then
  echo "Error: hcl2json not found. Install it to continue." >&2
  exit 1
fi

# ============================================================================
# Main: Discover and run tests
# ============================================================================
run_test() {
  local test_file="$1"
  local test_dir="$(dirname "$test_file")"
  local dockerfile_dir="${test_dir%/tests}"
  dockerfile_dir="${dockerfile_dir#./}"
  local context="./$dockerfile_dir"
  local test_name="$(basename "$test_file")"

  echo "  📋 Test: $test_name"
  echo "     Path: $test_file"

  # Find the bake target that uses this folder as context
  local bake_target=$(find_target_for_context "$context")

  if [ -z "$bake_target" ]; then
    echo "     ⏭️  Skipped: No bake target found for context $context"
    echo ""
    return 2  # Skip (neither pass nor fail)
  fi

  echo "     🎯 Target: $bake_target"

  # Determine which image to test against
  local target_to_run="$bake_target"
  if is_target_final "$bake_target"; then
    echo "     🐳 Target is final"
  else
    # Target is not final (e.g., cache-only), find a final target that inherits from it
    target_to_run=$(find_final_target_inheriting_from "$bake_target")
    if [ -n "$target_to_run" ]; then
      echo "     🐳 Target to test: $target_to_run (inherited from $bake_target)"
    fi
  fi

  if [ -z "$target_to_run" ]; then
    echo "     ❌ Failed: Could not determine target to run for $bake_target"
    echo ""
    return 1
  fi

  # Get full image tag (with registry, namespace, and version)
  local full_image_tag=$(get_image_tag_for_target "$target_to_run")

  # Run the test
  echo "     ▶️  Running test..."
  if bash "$test_file" "$full_image_tag"; then
    echo "     ✅ Passed"
    echo ""
    return 0
  else
    echo "     ❌ Failed"
    echo ""
    return 1
  fi
}

main() {
  test_count=0
  passed_count=0
  failed_count=0

  echo ""
  echo "🧪 Image Test Verification"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Group tests by folder
  local current_folder=""
  while IFS= read -r test_file; do
    local test_dir="$(dirname "$test_file")"
    local dockerfile_dir="${test_dir%/tests}"
    dockerfile_dir="${dockerfile_dir#./}"

    # Print folder header when folder changes
    if [ "$dockerfile_dir" != "$current_folder" ]; then
      if [ -n "$current_folder" ]; then
        echo ""
      fi
      echo "📁 $dockerfile_dir/"
      current_folder="$dockerfile_dir"
    fi

    test_count=$((test_count + 1))
    run_test "$test_file"
    result=$?

    if [ $result -eq 0 ]; then
      passed_count=$((passed_count + 1))
    elif [ $result -eq 1 ]; then
      failed_count=$((failed_count + 1))
    fi
  done < <(cd "$REPO_ROOT" && find . -path "*/tests/*_test.sh" -type f | sort)

  # Summary
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  if [ $failed_count -eq 0 ]; then
    echo "✨ All tests passed! ($passed_count/$test_count)"
    echo ""
  else
    echo "⚠️  Results: $passed_count passed, $failed_count failed out of $test_count tests"
    echo ""
    exit 1
  fi
}

main "$@"
