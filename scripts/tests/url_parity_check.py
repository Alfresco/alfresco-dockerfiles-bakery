#!/usr/bin/env python3
"""
Parity check: assert that the source model produces byte-identical download URLs
to the legacy Nexus layout for every artifact declared in the repository.

The legacy layout was:
  https://nexus.alfresco.com/nexus/repository/<repository>/<group-path>/<name>/<version>/<file>

where <repository> is now the artifact's `source` name. This verifies that the
URL built from sources.yaml matches that legacy URL exactly.

Exits non-zero on the first mismatch; prints the number of artifacts checked.
"""

import glob
import os
import sys

import yaml

SCRIPTS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
REPO_ROOT = os.path.abspath(os.path.join(SCRIPTS_DIR, ".."))
sys.path.insert(0, SCRIPTS_DIR)

import fetch_artifacts  # noqa: E402

LEGACY_BASE = "https://nexus.alfresco.com/nexus/repository"


def legacy_url(artifact):
    basename = fetch_artifacts.artifact_filename(artifact)
    group_path = artifact["group"].replace(".", "/")
    return (
        f"{LEGACY_BASE}/{artifact['source']}/{group_path}"
        f"/{artifact['name']}/{artifact['version']}/{basename}"
    )


def main():
    sources = fetch_artifacts.load_sources()

    checked = 0
    mismatches = []
    for manifest in sorted(glob.glob(os.path.join(REPO_ROOT, "**", "artifacts-*.yaml"), recursive=True)):
        with open(manifest, "r", encoding="utf-8") as manifest_file:
            data = yaml.safe_load(manifest_file) or {}
        for artifact in (data.get("artifacts") or {}).values():
            source_name = artifact.get("source")
            if source_name not in sources:
                mismatches.append(f"{manifest}: artifact references unknown source '{source_name}'")
                continue
            actual = fetch_artifacts.artifact_url(artifact, sources[source_name])
            expected = legacy_url(artifact)
            if actual != expected:
                mismatches.append(f"{manifest}: {artifact.get('name')}\n  expected {expected}\n  actual   {actual}")
            checked += 1

    if mismatches:
        print("URL parity FAILED:")
        for mismatch in mismatches:
            print(f"  - {mismatch}")
        sys.exit(1)

    print(f"URL parity OK: {checked} artifacts match the legacy Nexus layout")


if __name__ == "__main__":
    main()
