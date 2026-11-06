#!/usr/bin/env bats

# Tests for scripts/write_source_netrc.py: builds ~/.netrc entries for non-Nexus
# sources from their <PREFIX>_ARTIFACTS_USERNAME/PASSWORD env vars, skips the
# Nexus host and sources without credentials, and never logs secret values.

setup() {
    export SCRIPT_DIR="$BATS_TEST_DIRNAME/.."
    export NETRC_SCRIPT="$SCRIPT_DIR/write_source_netrc.py"

    export WORK="$(mktemp -d)"
    export SOURCES_FILE="$WORK/sources.yaml"
    export NETRC_PATH="$WORK/netrc"
    # The workflow writes the Nexus entry inline first; emulate that starting state.
    printf 'machine nexus.alfresco.com\n  login nexususer\n  password nexuspass\n' > "$NETRC_PATH"
}

teardown() {
    rm -rf "$WORK"
}

run_writer() {
    run env SOURCES_FILE="$SOURCES_FILE" NETRC_PATH="$NETRC_PATH" python3 "$NETRC_SCRIPT"
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
    run_writer
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
    export CLOUDSMITH_ARTIFACTS_USERNAME="csuser"
    export CLOUDSMITH_ARTIFACTS_PASSWORD="cssecret"
    run_writer
    [ "$status" -eq 0 ]
    grep -q "machine nexus.alfresco.com" "$NETRC_PATH"
    grep -q "machine dl.cloudsmith.io" "$NETRC_PATH"
    # Ordinary values are written verbatim (no quotes needed).
    grep -q 'login csuser' "$NETRC_PATH"
    grep -q 'password cssecret' "$NETRC_PATH"
}

@test "skips a non-Nexus source without credentials" {
    cat > "$SOURCES_FILE" << 'EOF'
sources:
  cloudsmith:
    url: https://dl.cloudsmith.io/basic/acme/maven
EOF
    local before
    before="$(cat "$NETRC_PATH")"
    run_writer
    [ "$status" -eq 0 ]
    [ "$(cat "$NETRC_PATH")" = "$before" ]
    [[ "$output" == *"unchanged"* ]]
}

@test "maps a hyphenated source name to an underscored prefix" {
    cat > "$SOURCES_FILE" << 'EOF'
sources:
  my-mirror:
    url: https://maven.example.com/repo
EOF
    export MY_MIRROR_ARTIFACTS_USERNAME="u"
    export MY_MIRROR_ARTIFACTS_PASSWORD="p"
    run_writer
    [ "$status" -eq 0 ]
    grep -q "machine maven.example.com" "$NETRC_PATH"
}

@test "does not print secret values" {
    cat > "$SOURCES_FILE" << 'EOF'
sources:
  cloudsmith:
    url: https://dl.cloudsmith.io/basic/acme/maven
EOF
    export CLOUDSMITH_ARTIFACTS_USERNAME="csuser"
    export CLOUDSMITH_ARTIFACTS_PASSWORD="TopSecretValue"
    run_writer
    [ "$status" -eq 0 ]
    [[ "$output" != *"TopSecretValue"* ]]
    [[ "$output" != *"csuser"* ]]
}

@test "stays parseable when the existing netrc has no trailing newline" {
    # Emulate an inline Nexus entry written without a final newline.
    printf 'machine nexus.alfresco.com\n  login nexususer\n  password nexuspass' > "$NETRC_PATH"
    cat > "$SOURCES_FILE" << 'EOF'
sources:
  cloudsmith:
    url: https://dl.cloudsmith.io/basic/acme/maven
EOF
    export CLOUDSMITH_ARTIFACTS_USERNAME="csuser"
    export CLOUDSMITH_ARTIFACTS_PASSWORD="cssecret"
    run_writer
    [ "$status" -eq 0 ]

    # Both entries must parse back via the netrc module, not be concatenated.
    run env NETRC_PATH="$NETRC_PATH" python3 - <<'PY'
import netrc, os
n = netrc.netrc(os.environ["NETRC_PATH"])
assert n.hosts["nexus.alfresco.com"][0] == "nexususer"
assert n.hosts["dl.cloudsmith.io"][0] == "csuser"
print("ok")
PY
    [ "$status" -eq 0 ]
    [[ "$output" == *"ok"* ]]
}

@test "secret_prefix normalises source names" {
    run python3 - << EOF
import sys
sys.path.insert(0, "$SCRIPT_DIR")
import write_source_netrc as w
cases = {
    "my-mirror": "MY_MIRROR",
    "my.mirror": "MY_MIRROR",
    "a--b": "A_B",
    "-lead-": "LEAD",
    "__x__y__": "X_Y",
    "releases": "RELEASES",
    "---": "",
}
for name, want in cases.items():
    assert w.secret_prefix(name) == want, (name, w.secret_prefix(name), want)
print("ok")
EOF
    [ "$status" -eq 0 ]
    [[ "$output" == *"ok"* ]]
}
