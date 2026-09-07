#!/bin/bash
# verify.sh - Auto-discover and run image tests
# Finds */tests/*_test.sh files and runs them against appropriate images
# based on docker-bake.hcl inheritance relationships

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Groups whose target graph is searched for images to test
BAKE_GROUPS="${BAKE_GROUPS:-default aps}"

BAKE_JSON="$(mktemp)"
trap 'rm -f "$BAKE_JSON"' EXIT

# ============================================================================
# Helper: Find the bake target that uses a given folder as its main context
# ============================================================================
find_target_for_context() {
  local context="$1"
  jq -r --arg context "$context" '
    .target | to_entries[] |
    select(.value.context == $context) |
    .key
  ' "$BAKE_JSON"
}

# ============================================================================
# Helper: Get the first final target that inherits from a given target
# ============================================================================
find_final_target_inheriting_from() {
  local parent_target="$1"
  jq -r --arg parent "$parent_target" '
    def is_final: [(.value.output // [])[].type] | index("cacheonly") | not;
    ([
      .target | to_entries[] |
      select((.value.contexts // {}) | has($parent)) |
      select(is_final) |
      .key
    ] | first) // empty
  ' "$BAKE_JSON"
}

# ============================================================================
# Helper: Check if a target is final (not cache-only)
# ============================================================================
is_target_final() {
  local target="$1"
  jq -e --arg target "$target" '
    [(.target[$target].output // [])[].type] | index("cacheonly") | not
  ' "$BAKE_JSON" >/dev/null 2>&1
}

# ============================================================================
# Helper: Get the fully resolved tag bake would build the target with
# ============================================================================
get_image_tag_for_target() {
  local target="$1"
  jq -r --arg target "$target" '.target[$target].tags[0] // empty' "$BAKE_JSON"
}

# ============================================================================
# Validation
# ============================================================================
if ! docker buildx version &>/dev/null; then
  echo "Error: docker buildx not found. Install it to continue." >&2
  exit 1
fi

# Resolve the bake graph once: expands matrices, image_tag() and the
# registry/namespace variables the way a build would
# shellcheck disable=SC2086
ARTIFACT_VERSIONS="$(python3 "$REPO_ROOT/scripts/print_artifact_versions.py")" \
  docker buildx bake --file "$REPO_ROOT/docker-bake.hcl" --print $BAKE_GROUPS \
  >"$BAKE_JSON" 2>/dev/null || {
  echo "Error: failed to resolve bake targets for groups: $BAKE_GROUPS" >&2
  exit 1
}

# ============================================================================
# Main: Discover and run tests
# ============================================================================
run_test() {
  local test_file="$1"
  local test_dir dockerfile_dir context test_name
  test_dir="$(dirname "$test_file")"
  dockerfile_dir="${test_dir%/tests}"
  dockerfile_dir="${dockerfile_dir#./}"
  context="$dockerfile_dir"
  test_name="$(basename "$test_file")"

  echo "  📋 Test: $test_name"
  echo "     Path: $test_file"

  # Find the bake target that uses this folder as context
  local bake_target
  bake_target=$(find_target_for_context "$context")

  if [ -z "$bake_target" ]; then
    echo "     ⏭️  Skipped: No bake target found for context $context"
    echo ""
    return 2
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

  local full_image_tag
  full_image_tag=$(get_image_tag_for_target "$target_to_run")

  if [ -z "$full_image_tag" ]; then
    echo "     ❌ Failed: Target $target_to_run has no tag"
    echo ""
    return 1
  fi

  echo "     🏷️  Image: $full_image_tag"
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
  local test_count=0 passed_count=0 failed_count=0 skipped_count=0 current_folder="" result

  echo ""
  echo "🧪 Image Test Verification"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  while IFS= read -r test_file; do
    local test_dir dockerfile_dir
    test_dir="$(dirname "$test_file")"
    dockerfile_dir="${test_dir%/tests}"
    dockerfile_dir="${dockerfile_dir#./}"

    if [ "$dockerfile_dir" != "$current_folder" ]; then
      [ -n "$current_folder" ] && echo ""
      echo "📁 $dockerfile_dir/"
      current_folder="$dockerfile_dir"
    fi

    test_count=$((test_count + 1))
    result=0
    run_test "$test_file" || result=$?

    if [ "$result" -eq 0 ]; then
      passed_count=$((passed_count + 1))
    elif [ "$result" -eq 1 ]; then
      failed_count=$((failed_count + 1))
    else
      skipped_count=$((skipped_count + 1))
    fi
  done < <(cd "$REPO_ROOT" && find . -path "*/tests/*_test.sh" -type f | sort)

  local skipped_note=""
  [ "$skipped_count" -gt 0 ] && skipped_note=", $skipped_count skipped"

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  if [ "$failed_count" -eq 0 ]; then
    echo "✨ All tests passed! ($passed_count/$test_count$skipped_note)"
    echo ""
  else
    echo "⚠️  Results: $passed_count passed, $failed_count failed$skipped_note out of $test_count tests"
    echo ""
    exit 1
  fi
}

main "$@"
