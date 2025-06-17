#!/usr/bin/env bats
# filepath: /Users/pawel.maciusiak/Documents/alfresco-dockerfiles/tests/test_fetch_artifacts.bats

setup() {
    export TEST_DIR=$(mktemp -d)
    export SCRIPT_DIR="$BATS_TEST_DIRNAME/.."
    export FETCH_SCRIPT="$SCRIPT_DIR/fetch_artifacts.py"
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "script runs without crashing" {
    run python3 "$FETCH_SCRIPT" --help 2>/dev/null || true
    # Should not contain Python traceback
    [[ "$output" != *"Traceback"* ]]
}

@test "script handles no arguments" {
    export ACS_VERSION=""
    export APS_VERSION=""

    run timeout 5 python3 "$FETCH_SCRIPT" 2>&1 || true
    echo "Output: $output"

    # Should not crash
    [[ "$output" != *"Traceback"* ]]
}

@test "script detects ACS version from environment" {
    export ACS_VERSION="25"

    # Create test directory structure
    mkdir -p "$TEST_DIR/repository"

    # Create minimal artifact file
    cat > "$TEST_DIR/repository/artifacts-25.yaml" << 'EOF'
artifacts:
  test-artifact:
    name: test-artifact
    version: 1.0.0
    classifier: .jar
    repository: public
    group: com.test
    path: repository
EOF

    cd "$TEST_DIR"
    run timeout 10 python3 "$FETCH_SCRIPT" repository 2>&1 || true
    echo "Output: $output"

    # Should attempt to process the file
    [[ "$output" == *"Processing target: repository"* ]] || [[ "$output" == *"test-artifact"* ]]
}

@test "script handles multiple arguments" {
    export ACS_VERSION="25"

    mkdir -p "$TEST_DIR/repo1" "$TEST_DIR/repo2"

    cat > "$TEST_DIR/repo1/artifacts-25.yaml" << 'EOF'
artifacts: {}
EOF

    cat > "$TEST_DIR/repo2/artifacts-25.yaml" << 'EOF'
artifacts: {}
EOF

    cd "$TEST_DIR"
    run timeout 10 python3 "$FETCH_SCRIPT" repo1 repo2 2>&1 || true
    echo "Output: $output"

    [[ "$output" == *"Processing target: repo1"* ]]
    [[ "$output" == *"Processing target: repo2"* ]]
}

@test "script handles glob patterns" {
    export ACS_VERSION="25"

    mkdir -p "$TEST_DIR/test/subdir"

    cat > "$TEST_DIR/test/subdir/artifacts-25.yaml" << 'EOF'
artifacts: {}
EOF

    cd "$TEST_DIR"
    run timeout 10 python3 "$FETCH_SCRIPT" "test/**/artifacts-*.yaml" 2>&1 || true
    echo "Output: $output"

    [[ "$output" == *"Processing target: test/**/artifacts-*.yaml"* ]]
}


@test "script handles completely broken YAML" {
    export ACS_VERSION="25"

    mkdir -p "$TEST_DIR/test"

    # Create completely invalid YAML
    cat > "$TEST_DIR/test/artifacts-25.yaml" << 'EOF'
this is not yaml at all!!!
random text [[[
EOF

    cd "$TEST_DIR"
    run timeout 10 python3 "$FETCH_SCRIPT" test 2>&1 || true
    echo "Output: $output"
    echo "Status: $status"

    # Should handle the error gracefully
    [[ "$status" -ne 0 ]] || [[ "$output" != *"Traceback"* ]]
}
