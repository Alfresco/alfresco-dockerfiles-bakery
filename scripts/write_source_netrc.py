"""
Populate ~/.netrc with per-source credentials for CI artifact fetches.

This script runs in CI only: it turns per-source GitHub secrets (delivered as
environment variables) into ~/.netrc entries. Local developers do not use it;
they maintain their own ~/.netrc by hand. Either way fetch_artifacts.py reads
credentials only from ~/.netrc, never from the environment.

The build/test/scan workflows write the Nexus ~/.netrc entry inline; this script
adds an entry for every other source whose credentials are supplied as the
`<PREFIX>_ARTIFACTS_USERNAME` / `<PREFIX>_ARTIFACTS_PASSWORD` environment
variables, where `<PREFIX>` is the source name mapped by
`fetch_artifacts.secret_prefix` (e.g. `my-mirror` -> `MY_MIRROR`). fetch_artifacts.py
then reads those credentials from ~/.netrc by host, exactly as it reads a
developer's own ~/.netrc. Only source names and hosts are logged, never values.

Environment:
  SOURCES_FILE  path to the sources definition file (default: sources.yaml)
  NETRC_PATH    netrc file to update (default: ~/.netrc)
  plus <PREFIX>_ARTIFACTS_USERNAME / <PREFIX>_ARTIFACTS_PASSWORD per source
"""

import logging
import os
import sys
import urllib.parse

import yaml

import fetch_artifacts
from fetch_artifacts import NEXUS_HOST, secret_prefix, validate_source_prefixes

SOURCES_FILE = os.getenv("SOURCES_FILE", fetch_artifacts.SOURCES_FILE)
NETRC_PATH = os.getenv("NETRC_PATH", os.path.join(os.path.expanduser("~"), ".netrc"))

logger = logging.getLogger(__name__)


def netrc_quote(value):
    """
    Double-quote a credential token so values containing whitespace or special
    characters round-trip through the stdlib netrc parser (Python 3.11+) that
    fetch_artifacts.py uses. Backslashes and double quotes are escaped.
    """
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def read_sources():
    if not os.path.isfile(SOURCES_FILE):
        logger.error(f"Sources file not found: {SOURCES_FILE}")
        sys.exit(1)
    with open(SOURCES_FILE, "r", encoding="utf-8") as sources_file:
        data = yaml.safe_load(sources_file) or {}
    sources = data.get("sources")
    if not sources:
        logger.error(f"No sources defined in {SOURCES_FILE}")
        sys.exit(1)
    return sources


def existing_machines(path):
    """Hosts already present as a `machine <host>` entry, so re-runs don't duplicate."""
    machines = set()
    if os.path.isfile(path):
        with open(path, "r", encoding="utf-8") as netrc_file:
            for line in netrc_file:
                tokens = line.split()
                if len(tokens) >= 2 and tokens[0] == "machine":
                    machines.add(tokens[1])
    return machines


def collect_entries(sources):
    validate_source_prefixes(sources)
    already = existing_machines(NETRC_PATH)
    entries = []
    seen_hosts = set()
    for name, spec in sources.items():
        url = (spec or {}).get("url")
        if not url:
            logger.error(f"Source '{name}' has no 'url' defined in {SOURCES_FILE}")
            sys.exit(1)
        host = urllib.parse.urlsplit(url.rstrip("/")).hostname
        # Nexus is written by the workflow's inline step; skip hosts already present.
        if not host or host == NEXUS_HOST or host in already or host in seen_hosts:
            continue
        prefix = secret_prefix(name)
        user_var = f"{prefix}_ARTIFACTS_USERNAME"
        pass_var = f"{prefix}_ARTIFACTS_PASSWORD"
        username = os.getenv(user_var)
        password = os.getenv(pass_var)
        if username and password:
            entries.append((host, username, password))
            seen_hosts.add(host)
            logger.info(f"Adding ~/.netrc entry for source '{name}' (host {host})")
        elif username or password:
            logger.error(
                f"Source '{name}': only one of {user_var} / {pass_var} is set; "
                f"set both or neither"
            )
            sys.exit(1)
        else:
            logger.info(f"No credentials for source '{name}' (host {host}); skipping")
    return entries


def main():
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    entries = collect_entries(read_sources())
    if not entries:
        logger.info("No additional source credentials configured; ~/.netrc unchanged")
        return
    # Create with secure permissions before writing any secret, and re-apply after.
    fd = os.open(NETRC_PATH, os.O_CREAT | os.O_APPEND | os.O_WRONLY, 0o600)
    os.chmod(NETRC_PATH, 0o600)
    with os.fdopen(fd, "a", encoding="utf-8") as netrc_file:
        for host, username, password in entries:
            netrc_file.write(
                f"machine {host}\n"
                f"  login {netrc_quote(username)}\n"
                f"  password {netrc_quote(password)}\n"
            )
    os.chmod(NETRC_PATH, 0o600)


if __name__ == "__main__":
    main()
