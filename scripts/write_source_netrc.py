"""
Write per-source ~/.netrc entries for the CI artifact fetch.

The build/test/scan workflows write the Nexus ~/.netrc entry themselves; this
script adds the entries for any other source hosts. It reads the sources from
sources.yaml and, for each source whose host is not the Nexus host (and not one
already handled), looks up credentials in the SECRETS_JSON object under
`<PREFIX>_ARTIFACTS_USERNAME` / `<PREFIX>_ARTIFACTS_PASSWORD`, where `<PREFIX>`
is the source name upper-cased with each run of non-alphanumeric characters
replaced by a single underscore (e.g. `my-mirror` -> `MY_MIRROR`). When both are
found it appends a `machine <host>` block (login/password) to the netrc file and
re-applies 0600 permissions. Sources missing either secret, and repeated hosts,
are left out, so the file is only extended for source hosts that actually have
credentials. Only source names and hosts are logged, never credential values.

Environment:
  SECRETS_JSON  JSON object of repository secrets (from toJSON(secrets))
  SOURCES_FILE  path to the sources definition file (default: sources.yaml)
  NETRC_PATH    netrc file to append to (default: ~/.netrc)
  NEXUS_HOST    host already written by the workflow and therefore skipped
                (default: nexus.alfresco.com)
"""

import json
import os
import re
import sys
from urllib.parse import urlsplit

try:
    import yaml
except ImportError:
    print("pyyaml not available; skipping per-source netrc entries", file=sys.stderr)
    sys.exit(0)

NEXUS_HOST = os.environ.get("NEXUS_HOST", "nexus.alfresco.com")
SOURCES_FILE = os.environ.get("SOURCES_FILE", "sources.yaml")
NETRC_PATH = os.environ.get("NETRC_PATH", os.path.join(os.path.expanduser("~"), ".netrc"))


def secret_prefix(source_name):
    """Map a source name to the secret-name prefix, e.g. 'my-repo' -> 'MY_REPO'."""
    return re.sub(r"[^A-Z0-9]+", "_", source_name.upper()).strip("_")


def netrc_quote(value):
    """
    Double-quote a credential token so values containing whitespace or special
    characters round-trip through Python's netrc parser instead of raising
    NetrcParseError. Backslashes and double quotes are escaped.
    """
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def main():
    if not os.path.isfile(SOURCES_FILE):
        print(f"No sources file at {SOURCES_FILE}; nothing to do")
        return

    try:
        secrets = json.loads(os.environ.get("SECRETS_JSON") or "{}")
    except json.JSONDecodeError:
        print("SECRETS_JSON is not valid JSON; treating as empty", file=sys.stderr)
        secrets = {}
    if not isinstance(secrets, dict):
        secrets = {}

    with open(SOURCES_FILE, "r", encoding="utf-8") as sources_file:
        data = yaml.safe_load(sources_file) or {}
    sources = data.get("sources") or {}

    # Nexus is written by the workflow's own step; everything else is handled here.
    seen_hosts = set()
    # Guard against two differently-named sources normalising to the same secret
    # prefix: reusing one credential pair across hosts could send a repository's
    # credentials to the wrong server.
    prefix_owner = {}
    entries = []
    for name, spec in sources.items():
        url = spec.get("url") if isinstance(spec, dict) else None
        if not url:
            continue
        host = urlsplit(url).hostname
        if not host or host == NEXUS_HOST:
            continue

        prefix = secret_prefix(name)
        owner = prefix_owner.get(prefix)
        if owner is not None and owner[1] != host:
            print(
                f"Sources '{owner[0]}' and '{name}' normalise to the same secret "
                f"prefix '{prefix}' but point to different hosts ({owner[1]}, {host}); "
                f"rename one so their credentials are not shared.",
                file=sys.stderr,
            )
            sys.exit(1)
        prefix_owner.setdefault(prefix, (name, host))

        if host in seen_hosts:
            continue

        username = secrets.get(f"{prefix}_ARTIFACTS_USERNAME")
        password = secrets.get(f"{prefix}_ARTIFACTS_PASSWORD")
        if username and password:
            entries.append((host, username, password))
            seen_hosts.add(host)
            print(f"Adding netrc entry for source '{name}' (host {host})")
        else:
            print(f"No credentials configured for source '{name}' (host {host}); skipping")

    if not entries:
        print("No additional source credentials configured; netrc unchanged")
        return

    with open(NETRC_PATH, "a", encoding="utf-8") as netrc_file:
        for host, username, password in entries:
            netrc_file.write(
                f"machine {host}\n"
                f"  login {netrc_quote(username)}\n"
                f"  password {netrc_quote(password)}\n"
            )
    os.chmod(NETRC_PATH, 0o600)


if __name__ == "__main__":
    main()
