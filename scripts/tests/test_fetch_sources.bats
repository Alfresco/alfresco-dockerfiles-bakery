#!/usr/bin/env bats

# Tests for the source model of fetch_artifacts.py: per-source credentials,
# anonymous access, 401/403 skip + summary, cross-host credential isolation,
# fail-fast validation and URL parity with the legacy Nexus layout.
#
# The fetch script resolves target arguments relative to the repository root, so
# the artifacts manifest under test lives in an in-repo scratch directory and is
# referenced by its relative name. Everything else (HOME/.netrc, sources.yaml,
# download destination, mock content) lives in a temp dir.

setup() {
    export SCRIPT_DIR="$BATS_TEST_DIRNAME/.."
    export FETCH_SCRIPT="$SCRIPT_DIR/fetch_artifacts.py"
    export MOCK_SERVER="$BATS_TEST_DIRNAME/mock_maven_repo.py"
    export ACTUAL_REPO_ROOT="$SCRIPT_DIR/.."

    export WORK="$(mktemp -d)"
    export HOME="$WORK/home"
    mkdir -p "$HOME"

    # In-repo scratch dir holding the manifest under test (referenced relatively).
    export TARGET_NAME="bats_src_test"
    export TARGET_DIR="$ACTUAL_REPO_ROOT/$TARGET_NAME"
    mkdir -p "$TARGET_DIR"

    export DEST="$WORK/dest"
    mkdir -p "$DEST"

    export ACS_VERSION="25"
    export SOURCES_FILE="$WORK/sources.yaml"
    MOCK_PIDS=()
    CACHE_DIRS=()
}

teardown() {
    for pid in "${MOCK_PIDS[@]}"; do
        kill "$pid" 2>/dev/null || true
    done
    for dir in "${CACHE_DIRS[@]}"; do
        rm -rf "$ACTUAL_REPO_ROOT/artifacts_cache/$dir"
    done
    rm -rf "$TARGET_DIR" "$WORK"
}

free_port() {
    python3 -c "import socket; s=socket.socket(); s.bind(('127.0.0.1',0)); print(s.getsockname()[1]); s.close()"
}

wait_for_port() {
    local port="$1"
    for _ in $(seq 1 100); do
        if python3 -c "import socket,sys; s=socket.socket(); s.settimeout(0.2); sys.exit(0 if s.connect_ex(('127.0.0.1',$port))==0 else 1)"; then
            return 0
        fi
        sleep 0.05
    done
    return 1
}

# start_mock <port> <root> <user> <pass> <log>
start_mock() {
    MOCK_PORT="$1" MOCK_ROOT="$2" MOCK_USER="$3" MOCK_PASS="$4" MOCK_LOG="$5" \
        python3 "$MOCK_SERVER" &
    MOCK_PIDS+=("$!")
    wait_for_port "$1"
}

# Place an artifact file at its Maven GAV path under <root>.
# seed_artifact <root> <group> <name> <version> <classifier>
seed_artifact() {
    local root="$1" group="$2" name="$3" version="$4" classifier="$5"
    local dir="$root/${group//.//}/$name/$version"
    mkdir -p "$dir"
    echo "artifact-bytes-$name-$version" > "$dir/$name-$version$classifier"
}

run_fetch() {
    run env SOURCES_FILE="$SOURCES_FILE" python3 "$FETCH_SCRIPT" "$TARGET_NAME" --log-level DEBUG
    echo "Output: $output"
}

@test "URL parity: source model matches the legacy Nexus layout" {
    run env -u SOURCES_FILE python3 "$BATS_TEST_DIRNAME/url_parity_check.py"
    echo "Output: $output"
    [ "$status" -eq 0 ]
    [[ "$output" == *"URL parity OK"* ]]
}

@test "fetches an artifact from an authenticated source" {
    local port root
    port="$(free_port)"
    root="$WORK/repo"
    seed_artifact "$root" "com.test" "test-artifact" "1.0.0" ".jar"

    printf 'machine 127.0.0.1\n  login alice\n  password secret\n' > "$HOME/.netrc"
    chmod 600 "$HOME/.netrc"
    start_mock "$port" "$root" "alice" "secret" ""

    cat > "$SOURCES_FILE" << EOF
sources:
  mocksrc:
    url: http://127.0.0.1:$port
EOF
    cat > "$TARGET_DIR/artifacts-25.yaml" << EOF
artifacts:
  test-artifact:
    name: test-artifact
    version: 1.0.0
    classifier: .jar
    group: com.test
    source: mocksrc
    path: $DEST
EOF
    CACHE_DIRS+=("mocksrc")

    run_fetch
    [ "$status" -eq 0 ]
    [ -f "$DEST/test-artifact-1.0.0.jar" ]
}

@test "fetches anonymously when the source has no credentials" {
    local port root
    port="$(free_port)"
    root="$WORK/repo"
    seed_artifact "$root" "com.test" "anon-artifact" "2.0.0" ".jar"

    # No .netrc entry -> anonymous; mock requires no credentials.
    start_mock "$port" "$root" "" "" ""

    cat > "$SOURCES_FILE" << EOF
sources:
  mocksrc:
    url: http://127.0.0.1:$port
EOF
    cat > "$TARGET_DIR/artifacts-25.yaml" << EOF
artifacts:
  anon-artifact:
    name: anon-artifact
    version: 2.0.0
    classifier: .jar
    group: com.test
    source: mocksrc
    path: $DEST
EOF
    CACHE_DIRS+=("mocksrc")

    run_fetch
    [ "$status" -eq 0 ]
    [ -f "$DEST/anon-artifact-2.0.0.jar" ]
}

@test "skips on 401 and reports it in the end-of-run summary" {
    local port root
    port="$(free_port)"
    root="$WORK/repo"
    seed_artifact "$root" "com.test" "authed-artifact" "1.2.3" ".jar"

    # Wrong credentials in .netrc -> mock returns 401.
    printf 'machine 127.0.0.1\n  login alice\n  password WRONG\n' > "$HOME/.netrc"
    chmod 600 "$HOME/.netrc"
    start_mock "$port" "$root" "alice" "secret" ""

    cat > "$SOURCES_FILE" << EOF
sources:
  mocksrc:
    url: http://127.0.0.1:$port
EOF
    cat > "$TARGET_DIR/artifacts-25.yaml" << EOF
artifacts:
  authed-artifact:
    name: authed-artifact
    version: 1.2.3
    classifier: .jar
    group: com.test
    source: mocksrc
    path: $DEST
EOF
    CACHE_DIRS+=("mocksrc")

    run_fetch
    [ "$status" -eq 0 ]
    [ ! -f "$DEST/authed-artifact-1.2.3.jar" ]
    [[ "$output" == *"Skipped 1 artifact"* ]]
    [[ "$output" == *"authed-artifact-1.2.3"* ]]
}

@test "skips on 403 and reports it in the summary" {
    local port root
    port="$(free_port)"
    root="$WORK/repo"
    # Group contains 'forbidden' so the mock returns 403 for this path.
    seed_artifact "$root" "com.forbidden" "blocked-artifact" "3.0.0" ".jar"

    start_mock "$port" "$root" "" "" ""

    cat > "$SOURCES_FILE" << EOF
sources:
  mocksrc:
    url: http://127.0.0.1:$port
EOF
    cat > "$TARGET_DIR/artifacts-25.yaml" << EOF
artifacts:
  blocked-artifact:
    name: blocked-artifact
    version: 3.0.0
    classifier: .jar
    group: com.forbidden
    source: mocksrc
    path: $DEST
EOF
    CACHE_DIRS+=("mocksrc")

    run_fetch
    [ "$status" -eq 0 ]
    [ ! -f "$DEST/blocked-artifact-3.0.0.jar" ]
    [[ "$output" == *"Skipped 1 artifact"* ]]
    [[ "$output" == *"HTTP 403"* ]]
}

@test "uses each source's own credentials across hosts (isolation)" {
    local port_a port_b root_a root_b log_a log_b
    port_a="$(free_port)"
    port_b="$(free_port)"
    root_a="$WORK/repo_a"
    root_b="$WORK/repo_b"
    log_a="$WORK/log_a"
    log_b="$WORK/log_b"
    seed_artifact "$root_a" "com.test" "artifact-a" "1.0.0" ".jar"
    seed_artifact "$root_b" "com.test" "artifact-b" "1.0.0" ".jar"

    # Distinct credentials per host; source A via 127.0.0.1, source B via localhost.
    cat > "$HOME/.netrc" << EOF
machine 127.0.0.1
  login userA
  password passA
machine localhost
  login userB
  password passB
EOF
    chmod 600 "$HOME/.netrc"

    start_mock "$port_a" "$root_a" "userA" "passA" "$log_a"
    start_mock "$port_b" "$root_b" "userB" "passB" "$log_b"

    cat > "$SOURCES_FILE" << EOF
sources:
  source_a:
    url: http://127.0.0.1:$port_a
  source_b:
    url: http://localhost:$port_b
EOF
    cat > "$TARGET_DIR/artifacts-25.yaml" << EOF
artifacts:
  artifact-a:
    name: artifact-a
    version: 1.0.0
    classifier: .jar
    group: com.test
    source: source_a
    path: $DEST
  artifact-b:
    name: artifact-b
    version: 1.0.0
    classifier: .jar
    group: com.test
    source: source_b
    path: $DEST
EOF
    CACHE_DIRS+=("source_a" "source_b")

    run_fetch
    [ "$status" -eq 0 ]
    [ -f "$DEST/artifact-a-1.0.0.jar" ]
    [ -f "$DEST/artifact-b-1.0.0.jar" ]

    # Each source's credentials reached only its own host.
    local auth_a auth_b
    auth_a="$(python3 -c "import base64;print('Basic '+base64.b64encode(b'userA:passA').decode())")"
    auth_b="$(python3 -c "import base64;print('Basic '+base64.b64encode(b'userB:passB').decode())")"
    grep -q "$auth_a" "$log_a"
    ! grep -q "$auth_b" "$log_a"
    grep -q "$auth_b" "$log_b"
    ! grep -q "$auth_a" "$log_b"
}

@test "does not fall back to the netrc default entry" {
    local port root log
    port="$(free_port)"
    root="$WORK/repo"
    log="$WORK/log"
    seed_artifact "$root" "com.test" "default-artifact" "1.0.0" ".jar"

    # Only a 'default' entry exists; the source host has no exact entry, so it
    # must be treated as anonymous rather than reusing the default credential.
    printf 'default\n  login defuser\n  password defpass\n' > "$HOME/.netrc"
    chmod 600 "$HOME/.netrc"

    start_mock "$port" "$root" "" "" "$log"

    cat > "$SOURCES_FILE" << EOF
sources:
  mocksrc:
    url: http://127.0.0.1:$port
EOF
    cat > "$TARGET_DIR/artifacts-25.yaml" << EOF
artifacts:
  default-artifact:
    name: default-artifact
    version: 1.0.0
    classifier: .jar
    group: com.test
    source: mocksrc
    path: $DEST
EOF
    CACHE_DIRS+=("mocksrc")

    run_fetch
    [ "$status" -eq 0 ]
    [ -f "$DEST/default-artifact-1.0.0.jar" ]
    # No Authorization header was sent: the default credential was not reused.
    ! grep -q "Basic " "$log"
}

@test "caches artifacts in a per-source directory" {
    local port root
    port="$(free_port)"
    root="$WORK/repo"
    seed_artifact "$root" "com.test" "cached-artifact" "9.9.9" ".jar"

    start_mock "$port" "$root" "" "" ""

    cat > "$SOURCES_FILE" << EOF
sources:
  cachesrc:
    url: http://127.0.0.1:$port
EOF
    cat > "$TARGET_DIR/artifacts-25.yaml" << EOF
artifacts:
  cached-artifact:
    name: cached-artifact
    version: 9.9.9
    classifier: .jar
    group: com.test
    source: cachesrc
    path: $DEST
EOF
    CACHE_DIRS+=("cachesrc")

    run_fetch
    [ "$status" -eq 0 ]
    [ -f "$ACTUAL_REPO_ROOT/artifacts_cache/cachesrc/cached-artifact-9.9.9.jar" ]
}

@test "fails fast on an unknown source" {
    cat > "$SOURCES_FILE" << EOF
sources:
  known:
    url: http://127.0.0.1:1
EOF
    cat > "$TARGET_DIR/artifacts-25.yaml" << EOF
artifacts:
  mystery:
    name: mystery
    version: 1.0.0
    classifier: .jar
    group: com.test
    source: nope
    path: $DEST
EOF

    run_fetch
    [ "$status" -ne 0 ]
    [[ "$output" == *"unknown source 'nope'"* ]]
}

@test "fails fast when an artifact has no source" {
    cat > "$SOURCES_FILE" << EOF
sources:
  known:
    url: http://127.0.0.1:1
EOF
    cat > "$TARGET_DIR/artifacts-25.yaml" << EOF
artifacts:
  mystery:
    name: mystery
    version: 1.0.0
    classifier: .jar
    group: com.test
    path: $DEST
EOF

    run_fetch
    [ "$status" -ne 0 ]
    [[ "$output" == *"has no 'source'"* ]]
}

@test "fails fast on a leftover repository key" {
    cat > "$SOURCES_FILE" << EOF
sources:
  known:
    url: http://127.0.0.1:1
EOF
    cat > "$TARGET_DIR/artifacts-25.yaml" << EOF
artifacts:
  legacy:
    name: legacy
    version: 1.0.0
    classifier: .jar
    group: com.test
    repository: known
    path: $DEST
EOF

    run_fetch
    [ "$status" -ne 0 ]
    [[ "$output" == *"removed 'repository' field"* ]]
}
