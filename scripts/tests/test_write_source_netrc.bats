#!/usr/bin/env bats

# Tests for scripts/write_source_netrc.py: builds ~/.netrc entries for non-Nexus
# sources from their <PREFIX>_ARTIFACTS_USERNAME/PASSWORD env vars, skips the
# Nexus host and sources without credentials, dedupes existing hosts, fails fast
# on partial credentials, and never logs secret values.

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
    grep -q 'login "csuser"' "$NETRC_PATH"
    grep -q 'password "cssecret"' "$NETRC_PATH"
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
    [[ "$output" == *"skipping"* ]]
}

@test "fails fast when only one per-source variable is set" {
    cat > "$SOURCES_FILE" << 'EOF'
sources:
  cloudsmith:
    url: https://dl.cloudsmith.io/basic/acme/maven
EOF
    export CLOUDSMITH_ARTIFACTS_USERNAME="csuser"
    unset CLOUDSMITH_ARTIFACTS_PASSWORD
    run_writer
    [ "$status" -ne 0 ]
    [[ "$output" == *"only one of CLOUDSMITH_ARTIFACTS_USERNAME / CLOUDSMITH_ARTIFACTS_PASSWORD"* ]]
}

@test "does not duplicate an existing host entry on re-run" {
    cat > "$SOURCES_FILE" << 'EOF'
sources:
  cloudsmith:
    url: https://dl.cloudsmith.io/basic/acme/maven
EOF
    export CLOUDSMITH_ARTIFACTS_USERNAME="csuser"
    export CLOUDSMITH_ARTIFACTS_PASSWORD="cssecret"
    run_writer
    [ "$status" -eq 0 ]
    run_writer
    [ "$status" -eq 0 ]
    [ "$(grep -c 'machine dl.cloudsmith.io' "$NETRC_PATH")" -eq 1 ]
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

@test "writes credentials that parse back via the netrc module, including specials" {
    cat > "$SOURCES_FILE" << 'EOF'
sources:
  cloudsmith:
    url: https://dl.cloudsmith.io/basic/acme/maven
EOF
    # Password contains a space, a quote and a backslash.
    export CLOUDSMITH_ARTIFACTS_USERNAME="cs user"
    export CLOUDSMITH_ARTIFACTS_PASSWORD='pa ss"x\y'
    run_writer
    [ "$status" -eq 0 ]

    run env NETRC_PATH="$NETRC_PATH" python3 - <<'PY'
import netrc, os
n = netrc.netrc(os.environ["NETRC_PATH"])
login, _, password = n.hosts["dl.cloudsmith.io"]
assert login == "cs user", repr(login)
assert password == 'pa ss"x\\y', repr(password)
print("ok")
PY
    [ "$status" -eq 0 ]
    [[ "$output" == *"ok"* ]]
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

@test "fails fast when two sources map to the same credential prefix" {
    cat > "$SOURCES_FILE" << 'EOF'
sources:
  my-mirror:
    url: https://maven.example.com/repo
  my_mirror:
    url: https://maven.other.test/repo
EOF
    run_writer
    [ "$status" -ne 0 ]
    [[ "$output" == *"MY_MIRROR"* ]]
}
