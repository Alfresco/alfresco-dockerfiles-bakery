"""
Collect the version of every artifact declared across the artifacts yaml files
and print them as a single JSON map of {artifact_name: version}.

Run this script with:
python3 scripts/print_artifact_versions.py [--override-artifacts-url URL]
"""

import argparse
import glob
import json
import os
import urllib.request
import yaml

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
APS_ROOT = os.path.join(REPO_ROOT, "aps")
ACS_VERSION = os.getenv("ACS_VERSION", "26")
APS_VERSION = os.getenv("APS_VERSION", "26")

def add_manifest_versions(versions, manifest):
    """Add artifact versions from a parsed manifest, with later entries winning."""
    artifacts = manifest.get("artifacts", {})
    for name, details in artifacts.items():
        version = details.get("version")
        if version is not None:
            versions[name] = version

def main(override_urls):
    acs_files = [
        file_path
        for file_path in glob.glob(os.path.join(REPO_ROOT, "**", f"artifacts-{ACS_VERSION}.yaml"), recursive=True)
        if not file_path.startswith(APS_ROOT + os.sep)
    ]
    aps_files = glob.glob(os.path.join(APS_ROOT, "**", f"artifacts-{APS_VERSION}.yaml"), recursive=True)

    versions = {}
    for file_path in sorted(acs_files) + sorted(aps_files):
        with open(file_path, "r", encoding="utf-8") as yaml_file:
            add_manifest_versions(versions, yaml.safe_load(yaml_file))

    for override_url in override_urls:
        with urllib.request.urlopen(override_url) as response:
            add_manifest_versions(versions, yaml.safe_load(response))

    print(json.dumps(versions, sort_keys=True))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Print artifact versions from Bakery manifests")
    parser.add_argument("--override-artifacts-url", action="append", default=[],
                        help="Remote artifacts YAML to merge after local manifests")
    args = parser.parse_args()
    main(args.override_artifacts_url)
