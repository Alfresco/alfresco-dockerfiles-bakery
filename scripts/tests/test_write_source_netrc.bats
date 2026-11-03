#!/usr/bin/env bats

# Tests for scripts/write_source_netrc.py: writes a netrc entry per non-Nexus
# source that has credentials, is a no-op otherwise, and never logs secrets.

setup() {
    export SCRIPT_DIR="$BATS_TEST_DIRNAME/.."
    export NETRC_SCRIPT="$SCRIPT_DIR/write_source_netrc.py"

    export WORK="$(mktemp -d)"
    export SOURCES_FILE="$WORK/sources.yaml"
    export NETRC_PATH="$WORK/netrc"
    # The workflow writes the Nexus entry first; emulate that starting state.
    printf 'machine nexus.alfresco.com\n  login nexususer\n  password nexuspass\n' > "$NETRC_PATH"
}

teardown() {
    rm -rf "$WORK"
}

run_script() {
    run env SOURCES_FILE="$SOURCES_FILE" NETRC_PATH="$NETRC_PATH" SECRETS_JSON="$1" \
        python3 "$NETRC_SCRIPT"
    echo "status=$status"
    echo "output=$output"
}

@test "no-op when every source is on the Nexus host" {
    cat > "$SOURCES_FILE" << 'EOF'
sources:
  public:
    url: https://nexus.alfresco.com/nexus/repository/public
  releases:
    url: https://nexus.alfresco.com/nexus/repository/releases
EOF

    local before
    before="$(cat "$NETRC_PATH")"
    run_script '{}'
    [ "$status" -eq 0 ]
    [ "$(cat "$NETRC_PATH")" = "$before" ]
}

@test "writes an entry for a non-Nexus source with credentials" {
    cat > "$SOURCES_FILE" << 'EOF'
sources:
  public:
    url: https://nexus.alfresco.com/nexus/repository/public
  cloudsmith:
    url: https://dl.cloudsmith.io/basic/acme/maven
EOF

    run_script '{"CLOUDSMITH_ARTIFACTS_USERNAME":"csuser","CLOUDSMITH_ARTIFACTS_PASSWORD":"cssecret"}'
    [ "$status" -eq 0 ]
    # Nexus entry preserved, Cloudsmith entry appended for its host.
    grep -q "machine nexus.alfresco.com" "$NETRC_PATH"
    grep -q "machine dl.cloudsmith.io" "$NETRC_PATH"
    grep -q "login csuser" "$NETRC_PATH"
    grep -q "password cssecret" "$NETRC_PATH"
}

@test "skips a non-Nexus source without credentials" {
    cat > "$SOURCES_FILE" << 'EOF'
sources:
  cloudsmith:
    url: https://dl.cloudsmith.io/basic/acme/maven
EOF

    local before
    before="$(cat "$NETRC_PATH")"
    run_script '{}'
    [ "$status" -eq 0 ]
    [ "$(cat "$NETRC_PATH")" = "$before" ]
    [[ "$output" == *"skipping"* ]]
}

@test "maps a hyphenated source name to an underscored secret prefix" {
    cat > "$SOURCES_FILE" << 'EOF'
sources:
  my-mirror:
    url: https://maven.example.com/repo
EOF

    run_script '{"MY_MIRROR_ARTIFACTS_USERNAME":"u","MY_MIRROR_ARTIFACTS_PASSWORD":"p"}'
    [ "$status" -eq 0 ]
    grep -q "machine maven.example.com" "$NETRC_PATH"
}

@test "does not print secret values" {
    cat > "$SOURCES_FILE" << 'EOF'
sources:
  cloudsmith:
    url: https://dl.cloudsmith.io/basic/acme/maven
EOF

    run_script '{"CLOUDSMITH_ARTIFACTS_USERNAME":"csuser","CLOUDSMITH_ARTIFACTS_PASSWORD":"TopSecretValue"}'
    [ "$status" -eq 0 ]
    [[ "$output" != *"TopSecretValue"* ]]
    [[ "$output" != *"csuser"* ]]
}
