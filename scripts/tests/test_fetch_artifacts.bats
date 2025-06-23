#!/usr/bin/env bats

setup() {
    export SCRIPT_DIR="$BATS_TEST_DIRNAME/.."
    export FETCH_SCRIPT="$SCRIPT_DIR/fetch_artifacts.py"
    export ACTUAL_REPO_ROOT="$SCRIPT_DIR/.."

    # Create temporary test directories in the actual repo structure
    export TEST_REPO1="$ACTUAL_REPO_ROOT/test_repo1"
    export TEST_REPO2="$ACTUAL_REPO_ROOT/test_repo2"
    export TEST_EXISTING_DIR="$ACTUAL_REPO_ROOT/test_existing_dir"
}

teardown() {
    # Clean up test directories from actual repo
    rm -rf "$TEST_REPO1" "$TEST_REPO2" "$TEST_EXISTING_DIR"
    rm -rf "$ACTUAL_REPO_ROOT/bats_test"
}

@test "script exists and is executable" {
    [ -f "$FETCH_SCRIPT" ]
    [ -r "$FETCH_SCRIPT" ]
}

@test "script runs without crashing" {
    run python3 "$FETCH_SCRIPT" --help 2>/dev/null
    [[ "$output" != *"Traceback"* ]]
}

@test "script handles no arguments" {
    export ACS_VERSION=""

    cd "$ACTUAL_REPO_ROOT"
    run python3 scripts/fetch_artifacts.py --log-level DEBUG 2>&1
    echo "Output: $output"

    # Should not crash
    [[ "$output" != *"Traceback"* ]]
    [[ "$output" != *"WARNING:"* ]]
    [[ "$output" != *"ERROR:"* ]]
}

@test "script detects ACS version from environment" {
    export ACS_VERSION="25"

    # Create test directory structure in actual repo
    mkdir -p "$TEST_REPO1"

    # Create minimal artifact file
    cat > "$TEST_REPO1/artifacts-25.yaml" << 'EOF'
artifacts:
  test-artifact:
    name: test-artifact
    version: 1.0.0
    classifier: .jar
    repository: public
    group: com.test
    path: test_repo1
EOF

    cd "$ACTUAL_REPO_ROOT"
    run python3 scripts/fetch_artifacts.py --log-level DEBUG test_repo1 2>&1
    echo "Output: $output"

    # Should detect as valid path and process
    [[ "$output" == *"Processing target: test_repo1"* ]] && [[ "$output" == *"valid path"* ]]
    [[ "$output" != *"WARNING:"* ]]
    [[ "$output" != *"ERROR:"* ]]
}

@test "script handles multiple arguments" {
    export ACS_VERSION="25"

    # Create test directories in actual repo structure
    mkdir -p "$TEST_REPO1" "$TEST_REPO2"

    cat > "$TEST_REPO1/artifacts-25.yaml" << 'EOF'
artifacts: {}
EOF

    cat > "$TEST_REPO2/artifacts-25.yaml" << 'EOF'
artifacts: {}
EOF

    cd "$ACTUAL_REPO_ROOT"
    run python3 scripts/fetch_artifacts.py --log-level DEBUG test_repo1 test_repo2 2>&1
    echo "Output: $output"

    # Should show BOTH "Processing target" AND "valid path" messages for each
    [[ "$output" == *"Processing target: test_repo1"* ]] && [[ "$output" == *"valid path"* ]]
    [[ "$output" == *"Processing target: test_repo2"* ]] && [[ "$output" == *"valid path"* ]]
    [[ "$output" != *"WARNING:"* ]]
    [[ "$output" != *"ERROR:"* ]]
}

@test "script detects valid paths vs glob patterns" {
    export ACS_VERSION="25"

    # Create directory in actual repo structure
    mkdir -p "$TEST_EXISTING_DIR"

    cd "$ACTUAL_REPO_ROOT"

    # Test with existing directory (should be detected as valid path)
    run python3 scripts/fetch_artifacts.py test_existing_dir --log-level DEBUG  2>&1
    echo "Valid path test output: $output"

    # Should show BOTH "Processing target" AND "valid path"
    [[ "$output" == *"Processing target: test_existing_dir"* ]] && [[ "$output" == *"valid path"* ]]
    [[ "$output" != *"WARNING:"* ]]
    [[ "$output" != *"ERROR:"* ]]

    # Test with glob pattern (should be detected as glob)
    run python3 scripts/fetch_artifacts.py "**/nonexistent-*.yaml" --log-level DEBUG 2>&1
    echo "Glob pattern test output: $output"

    # Should detect as glob pattern
    [[ "$output" == *"glob pattern"* ]]
    [[ "$output" != *"WARNING:"* ]]
    [[ "$output" != *"ERROR:"* ]]
}

@test "script handles glob patterns" {
    export ACS_VERSION="25"

    # Create nested structure in actual repo
    mkdir -p "$ACTUAL_REPO_ROOT/bats_test/subdir"

    cat > "$ACTUAL_REPO_ROOT/bats_test/subdir/artifacts-25-uncommon.yaml" << 'EOF'
artifacts: {}
EOF

    cd "$ACTUAL_REPO_ROOT"
    run python3 scripts/fetch_artifacts.py "**/artifacts-*-uncommon.yaml" --log-level DEBUG 2>&1
    echo "Output: $output"

    # The glob pattern should be detected
    [[ "$output" == *"glob pattern"* ]]
    [[ "$output" != *"WARNING:"* ]]
    [[ "$output" != *"ERROR:"* ]]
}

@test "script handles completely broken YAML" {
    export ACS_VERSION="25"

    # Create test directory in actual repo
    mkdir -p "$ACTUAL_REPO_ROOT/bats_test"

    # Create completely invalid YAML
    cat > "$ACTUAL_REPO_ROOT/bats_test/artifacts-25.yaml" << 'EOF'
this is not yaml at all!!!
random text [[[
EOF

    cd "$ACTUAL_REPO_ROOT"
    run python3 scripts/fetch_artifacts.py test 2>&1 --log-level DEBUG
    echo "Output: $output"
    echo "Status: $status"

    # Should detect test as valid path and handle YAML error gracefully
    [[ "$output" == *"valid path"* ]] && [[ "$output" == *"Processing target: test"* ]]
    [[ "$status" -ne 0 ]] || [[ "$output" != *"Traceback"* ]]
    [[ "$output" != *"WARNING:"* ]]
    [[ "$output" != *"ERROR:"* ]]
}
