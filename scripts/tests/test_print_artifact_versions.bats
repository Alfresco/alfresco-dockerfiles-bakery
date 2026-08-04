#!/usr/bin/env bats

setup() {
    export SCRIPT_DIR="$BATS_TEST_DIRNAME/.."
    export SCRIPT="$SCRIPT_DIR/print_artifact_versions.py"
    export ACTUAL_REPO_ROOT="$SCRIPT_DIR/.."

    export TEST_TOPLEVEL_DIR="$ACTUAL_REPO_ROOT/bats_pav_test"
    export TEST_APS_DIR="$ACTUAL_REPO_ROOT/aps/bats_pav_test"

    export ACS_VERSION="999"
    export APS_VERSION="998"
}

teardown() {
    rm -rf "$TEST_TOPLEVEL_DIR" "$TEST_APS_DIR"
}

@test "script exists and is readable" {
    [ -f "$SCRIPT" ]
    [ -r "$SCRIPT" ]
}

@test "script runs and prints valid JSON" {
    cd "$ACTUAL_REPO_ROOT"
    run python3 "$SCRIPT"
    [ "$status" -eq 0 ]
    echo "$output" | python3 -c "import json,sys; json.loads(sys.stdin.read())"
}

@test "script picks up top-level artifacts for ACS_VERSION" {
    mkdir -p "$TEST_TOPLEVEL_DIR"
    cat > "$TEST_TOPLEVEL_DIR/artifacts-999.yaml" << 'EOF'
artifacts:
  bats-toplevel-artifact:
    version: "1.2.3"
EOF

    cd "$ACTUAL_REPO_ROOT"
    run python3 "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" == *'"bats-toplevel-artifact": "1.2.3"'* ]]
}

@test "script picks up aps/ artifacts for APS_VERSION" {
    mkdir -p "$TEST_APS_DIR"
    cat > "$TEST_APS_DIR/artifacts-998.yaml" << 'EOF'
artifacts:
  bats-aps-artifact:
    version: "4.5.6"
EOF

    cd "$ACTUAL_REPO_ROOT"
    run python3 "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" == *'"bats-aps-artifact": "4.5.6"'* ]]
}

@test "script excludes aps/ directory when scanning for ACS_VERSION" {
    mkdir -p "$TEST_APS_DIR"
    cat > "$TEST_APS_DIR/artifacts-999.yaml" << 'EOF'
artifacts:
  bats-aps-should-be-excluded:
    version: "9.9.9"
EOF

    cd "$ACTUAL_REPO_ROOT"
    run python3 "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" != *"bats-aps-should-be-excluded"* ]]
}

@test "script skips artifacts with a missing version" {
    mkdir -p "$TEST_TOPLEVEL_DIR"
    cat > "$TEST_TOPLEVEL_DIR/artifacts-999.yaml" << 'EOF'
artifacts:
  bats-no-version-artifact:
    name: bats-no-version-artifact
EOF

    cd "$ACTUAL_REPO_ROOT"
    run python3 "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" != *"bats-no-version-artifact"* ]]
}
