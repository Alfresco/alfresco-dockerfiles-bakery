"""
Process artifacts yml files to download the artifacts from the Alfresco Nexus repository

Run this script with:
python3 scripts/fetch_artifacts.py [<target_subdir>]

The target_subdir is the subdirectory where the artifacts yaml files are located (optional)
"""

import netrc
import os
import shutil
import sys
import tempfile
import urllib.request
import hashlib
import yaml

# Custom exceptions
class ChecksumMismatchError(Exception):
    """
    Exception raised when the checksum of the downloaded artifact does not match the source checksum
    """

# Constants
REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
TEMP_DIR = tempfile.mkdtemp()
ACS_VERSION = os.getenv("ACS_VERSION", "25")
APS_VERSION = os.getenv("APS_VERSION", "25")
MAVEN_FQDN = os.getenv("MAVEN_FQDN", "nexus.alfresco.com")
MAVEN_REPO = os.getenv("MAVEN_REPO", f"https://{MAVEN_FQDN}/nexus/repository")

def get_checksums(artifact_checksum, artifact_url, artifact_file_path):
    """
    Get source checksum that must match and the computed checksum
    """
    if artifact_checksum and artifact_checksum.split(":")[0] in ["md5", "sha1", "sha256", "sha512"]:
        checksum_type = artifact_checksum.split(":")[0]
    else:
        return None, None
    if not artifact_checksum.split(":")[1]:
        try:
            with urllib.request.urlopen(f"{artifact_url}.{checksum_type}") as checksum_response:
                checksum = checksum_response.read().decode("utf-8").strip()
        except urllib.error.HTTPError as e:
            print(f"Failed to fetch checksum from {artifact_url}.{checksum_type}: {e}")
            return None, None
    else:
        checksum = artifact_checksum.split(":")[1]
    with open(artifact_file_path, "rb") as artifact_file:
        computed_checksum = hashlib.new(checksum_type, artifact_file.read()).hexdigest()
    return checksum, computed_checksum


def do_parse_and_mvn_fetch(file_path):
    """
    Parse the artifacts yaml file and download the artifacts from the Alfresco Nexus repository
    """
    with open(file_path, "r", encoding="utf-8") as yaml_file:
        data = yaml.safe_load(yaml_file)
        artifacts = data.get("artifacts", {})

    for artifact_name, artifact_details in artifacts.items():
        artifact_repo = artifact_details.get("repository")
        artifact_name = artifact_details.get("name")
        artifact_version = artifact_details.get("version")
        artifact_ext = artifact_details.get("classifier", "")
        artifact_checksum = artifact_details.get("checksum")
        artifact_group = artifact_details.get("group")
        artifact_path = artifact_details.get("path")

        artifact_baseurl = f"{MAVEN_REPO}/{artifact_repo}"
        artifact_tmp_path = os.path.join(TEMP_DIR, f"{artifact_name}-{artifact_version}{artifact_ext}")
        artifact_cache_path = os.path.join(REPO_ROOT, "artifacts_cache", f"{artifact_name}-{artifact_version}{artifact_ext}")
        artifact_final_path = os.path.join(artifact_path, f"{artifact_name}-{artifact_version}{artifact_ext}")
        artifact_url = f"{artifact_baseurl}/{artifact_group.replace('.', '/')}/{artifact_name}/{artifact_version}/{artifact_name}-{artifact_version}{artifact_ext}"

        # Newline for better readability
        print()

        # Check if the artifact is already present
        if os.path.isfile(artifact_final_path):
            print(f"Artifact {artifact_name}-{artifact_version} already present.")
            src_checksum, computed_checksum = get_checksums(artifact_checksum, artifact_url, artifact_final_path)
            if not src_checksum and not computed_checksum:
                print('No valid checksum found, skipping verification...')
                continue
            if src_checksum == computed_checksum:
                print(f"Checksum matched for {artifact_name}-{artifact_version}{artifact_ext}")
                continue
            print(f"Checksum mismatch for {artifact_name}-{artifact_version}{artifact_ext}. Re-downloading...")
            os.remove(artifact_final_path)

        if os.path.isfile(artifact_cache_path):
            src_checksum, computed_checksum = get_checksums(artifact_checksum, artifact_url, artifact_cache_path)
            if src_checksum == computed_checksum:
                print(f"Artifact {artifact_name}-{artifact_version} already present in cache, copying...")
                shutil.copy(artifact_cache_path, artifact_final_path)
                continue
            else:
                print(f"Checksum mismatch for {artifact_name}-{artifact_version}{artifact_ext}. Re-downloading...")
                os.remove(artifact_cache_path)

        # Download the artifact
        print(f"Downloading {artifact_group}:{artifact_name} {artifact_version} from {artifact_baseurl}")
        try:
            with urllib.request.urlopen(artifact_url) as response, open(artifact_tmp_path, 'wb') as out_file:
                shutil.copyfileobj(response, out_file)

            checksums = get_checksums(
                artifact_checksum, artifact_url,
                artifact_tmp_path
            )
            if checksums[0] != checksums[1]:
                raise ChecksumMismatchError(
                    f"Checksum mismatch for {artifact_name}-{artifact_version}{artifact_ext}."
                    f"Expected: {checksums[0]}, Computed: {checksums[1]}"
                )

        except urllib.error.HTTPError as e:
            if e.code == 401:
                print("Invalid or missing credentials, skipping...")
                continue
            elif e.code == 403:
                print("Forbidden access, skipping...")
                continue
            else:
                # rethrow the exception to exit with failure
                raise e

        # Move to cache and copy to final path
        shutil.move(artifact_tmp_path, artifact_cache_path)
        shutil.copy(artifact_cache_path, artifact_final_path)

def find_targets_recursively(root_path):
    """
    Find all the artifacts yaml files from the root path recursively which match the given pattern
    """
    patterns = []

    # Add ACS pattern if ACS_VERSION is provided and not empty
    if ACS_VERSION and ACS_VERSION != "null":
        acs_pattern = f"artifacts-{ACS_VERSION}.yaml"
        patterns.append(acs_pattern)

    # Add APS pattern if APS_VERSION is provided and not empty
    if APS_VERSION and APS_VERSION != "null":
        aps_pattern = f"artifacts-{APS_VERSION}-aps.yaml"
        patterns.append(aps_pattern)

    # If no patterns are defined, warn the user
    if not patterns:
        print("Warning: Neither ACS_VERSION nor APS_VERSION is provided. No artifacts will be downloaded.")
        return []

    targets = []
    for root, _, files in os.walk(root_path):
        for file in files:
            if file in patterns:
                targets.append(os.path.join(root, file))

    return targets

def setup_basic_auth(username, password):
    """
    Setup basic authentication for the Nexus repository
    """
    password_mgr = urllib.request.HTTPPasswordMgrWithDefaultRealm()
    password_mgr.add_password(None, MAVEN_REPO, username, password)
    auth_handler = urllib.request.HTTPBasicAuthHandler(password_mgr)
    opener = urllib.request.build_opener(auth_handler)
    urllib.request.install_opener(opener)

def get_credentials_from_netrc(machine):
    """
    Get credentials from .netrc file for the specified machine
    """
    try:
        netrc_file = netrc.netrc()
        auth_info = netrc_file.authenticators(machine)
        if auth_info:
            login, _, password = auth_info
            return login, password
    except FileNotFoundError:
        # Ignore if .netrc file is not found
        pass
    except netrc.NetrcParseError as e:
        print(f"Error parsing .netrc file: {e}")
    return None, None

def main(target_subdir=""):
    """
    Find all the artifacts yaml files and process them
    """
    targets = find_targets_recursively(os.path.sep.join([REPO_ROOT, target_subdir]))

    username, password = get_credentials_from_netrc('nexus.alfresco.com')
    if os.getenv('NEXUS_USERNAME') and os.getenv('NEXUS_PASSWORD'):
        username = os.getenv('NEXUS_USERNAME')
        password = os.getenv('NEXUS_PASSWORD')
    if username and password:
        setup_basic_auth(username, password)

    for target_file in targets:
        do_parse_and_mvn_fetch(target_file)

if __name__ == "__main__":
    target_directory = sys.argv[1] if len(sys.argv) > 1 else ""
    main(target_directory)
