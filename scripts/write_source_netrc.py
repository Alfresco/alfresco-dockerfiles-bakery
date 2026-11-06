"""
Populate ~/.netrc with per-source credentials for CI artifact fetches.

CI only. The workflows write the Nexus ~/.netrc entry inline; this script adds an
entry for every other source whose credentials are supplied as the
`<PREFIX>_ARTIFACTS_USERNAME` / `<PREFIX>_ARTIFACTS_PASSWORD` environment variables
(from GitHub secrets), where `<PREFIX>` is the source name mapped by `secret_prefix`
(e.g. `my-mirror` -> `MY_MIRROR`). fetch_artifacts.py then reads them from ~/.netrc
by host. Only source names and hosts are logged.

Environment:
  SOURCES_FILE  path to the sources definition file (default: sources.yaml)
  NETRC_PATH    netrc file to update (default: ~/.netrc)
  plus <PREFIX>_ARTIFACTS_USERNAME / <PREFIX>_ARTIFACTS_PASSWORD per source
"""

import logging
import os
import re
import sys
import urllib.parse

import yaml

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SOURCES_FILE = os.getenv("SOURCES_FILE", os.path.join(REPO_ROOT, "sources.yaml"))
NETRC_PATH = os.getenv("NETRC_PATH", os.path.join(os.path.expanduser("~"), ".netrc"))
NEXUS_HOST = os.getenv("MAVEN_FQDN", "nexus.alfresco.com")

logger = logging.getLogger(__name__)


def secret_prefix(source_name):
    """
    Map a source name to its secret-name prefix: upper-cased, with every run of
    non-alphanumeric characters collapsed to a single underscore and leading and
    trailing underscores removed (e.g. 'my-mirror' -> 'MY_MIRROR').
    """
    return re.sub(r"[^A-Z0-9]+", "_", str(source_name).upper()).strip("_")


def main():
    logging.basicConfig(level=logging.INFO, format="%(message)s")

    if not os.path.isfile(SOURCES_FILE):
        logger.error(f"Sources file not found: {SOURCES_FILE}")
        sys.exit(1)
    with open(SOURCES_FILE, "r", encoding="utf-8") as sources_file:
        sources = (yaml.safe_load(sources_file) or {}).get("sources") or {}

    entries = []
    for name, spec in sources.items():
        url = (spec or {}).get("url")
        if not url:
            continue
        host = urllib.parse.urlsplit(url.rstrip("/")).hostname
        # The Nexus entry is written inline by the workflow; skip it here.
        if not host or host == NEXUS_HOST:
            continue
        prefix = secret_prefix(name)
        username = os.getenv(f"{prefix}_ARTIFACTS_USERNAME")
        password = os.getenv(f"{prefix}_ARTIFACTS_PASSWORD")
        if username and password:
            entries.append((host, username, password))
            logger.info(f"Adding ~/.netrc entry for source '{name}' (host {host})")

    if not entries:
        logger.info("No additional source credentials configured; ~/.netrc unchanged")
        return

    # Create with 0600 before writing any secret; lead with a newline so the first
    # entry can't glue onto a previous line that lacks one.
    fd = os.open(NETRC_PATH, os.O_CREAT | os.O_APPEND | os.O_WRONLY, 0o600)
    with os.fdopen(fd, "a", encoding="utf-8") as netrc_file:
        netrc_file.write("\n")
        for host, username, password in entries:
            netrc_file.write(f"machine {host}\n  login {username}\n  password {password}\n")


if __name__ == "__main__":
    main()
