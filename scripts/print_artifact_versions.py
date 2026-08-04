"""
Collect the version of every artifact declared across the artifacts yaml files
and print them as a single JSON map of {artifact_name: version}.

Run this script with:
python3 scripts/print_artifact_versions.py
"""

import glob
import json
import os
import yaml

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
APS_ROOT = os.path.join(REPO_ROOT, "aps")
ACS_VERSION = os.getenv("ACS_VERSION", "26")
APS_VERSION = os.getenv("APS_VERSION", "26")

def main():
    acs_files = [
        file_path
        for file_path in glob.glob(os.path.join(REPO_ROOT, "**", f"artifacts-{ACS_VERSION}.yaml"), recursive=True)
        if not file_path.startswith(APS_ROOT + os.sep)
    ]
    aps_files = glob.glob(os.path.join(APS_ROOT, "**", f"artifacts-{APS_VERSION}.yaml"), recursive=True)

    versions = {}
    for file_path in sorted(acs_files) + sorted(aps_files):
        with open(file_path, "r", encoding="utf-8") as yaml_file:
            data = yaml.safe_load(yaml_file)
        artifacts = data.get("artifacts", {})
        for name, details in artifacts.items():
            version = details.get("version")
            if version is not None:
                versions[name] = version

    print(json.dumps(versions, sort_keys=True))

if __name__ == "__main__":
    main()
