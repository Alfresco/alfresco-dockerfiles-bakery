"""
Process artifacts yml files to download the artifacts from the Alfresco Nexus repository
"""

import netrc
import os
import shutil
import sys
import tempfile
import urllib.request

import yaml

# Constants
REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
TEMP_DIR = tempfile.mkdtemp()
ACS_VERSION = os.getenv("ACS_VERSION", "23")
MAVEN_FQDN = os.getenv("MAVEN_FQDN", "nexus.alfresco.com")
MAVEN_REPO = os.getenv("MAVEN_REPO", f"https://{MAVEN_FQDN}/nexus/repository")

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
        artifact_group = artifact_details.get("group")
        artifact_path = artifact_details.get("path")

        artifact_baseurl = f"{MAVEN_REPO}/{artifact_repo}"
        artifact_tmp_path = os.path.join(TEMP_DIR, f"{artifact_name}-{artifact_version}{artifact_ext}")
        artifact_cache_path = os.path.join(REPO_ROOT, "artifacts_cache", f"{artifact_name}-{artifact_version}{artifact_ext}")
        artifact_final_path = os.path.join(artifact_path, f"{artifact_name}-{artifact_version}{artifact_ext}")

        # Newline for better readability
        print()

        # Check if the artifact is already present
        if os.path.isfile(artifact_final_path):
            print(f"Artifact {artifact_name}-{artifact_version} already present, skipping...")
            continue

        if os.path.isfile(artifact_cache_path):
            print(f"Artifact {artifact_name}-{artifact_version} already present in cache, copying...")
            shutil.copy(artifact_cache_path, artifact_final_path)
            continue

        # Download the artifact
        artifact_url = f"{artifact_baseurl}/{artifact_group.replace('.', '/')}/{artifact_name}/{artifact_version}/{artifact_name}-{artifact_version}{artifact_ext}"
        print(f"Downloading {artifact_group}:{artifact_name} {artifact_version} from {artifact_baseurl}")
        try:
            with urllib.request.urlopen(artifact_url) as response, open(artifact_tmp_path, 'wb') as out_file:
                shutil.copyfileobj(response, out_file)
        except Exception as e:
            print(f"Skipping after failure: {e}")
            if os.path.exists(artifact_tmp_path):
                os.remove(artifact_tmp_path)
            continue

        # Move to cache and copy to final path
        shutil.move(artifact_tmp_path, artifact_cache_path)
        shutil.copy(artifact_cache_path, artifact_final_path)

def find_targets_recursively(root_path, subdir=""):
    """
    Find all the artifacts yaml files from the root path recursively which match the given pattern
    """
    pattern = f"artifacts-{ACS_VERSION}.yaml"
    targets = []
    for root, _, files in os.walk(root_path):
        for file in files:
            if file == pattern:
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
    except netrc.NetrcParseError:
        print("Error parsing .netrc file")
    return None, None

def main(target_subdir=""):
    """
    Find all the artifacts yaml files and process them
    """
    targets = find_targets_recursively(REPO_ROOT, target_subdir)

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
