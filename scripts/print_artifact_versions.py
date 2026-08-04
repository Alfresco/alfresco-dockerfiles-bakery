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
ACS_VERSION = os.getenv("ACS_VERSION", "26")
APS_VERSION = os.getenv("APS_VERSION", "26")

def main():
    patterns = [
        os.path.join(REPO_ROOT, "**", f"artifacts-{ACS_VERSION}.yaml"),
        os.path.join(REPO_ROOT, "aps", "**", f"artifacts-{APS_VERSION}.yaml"),
    ]

    versions = {}
    for pattern in patterns:
        for file_path in sorted(glob.glob(pattern, recursive=True)):
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
