"""
Process artifacts yml files to download the artifacts from the Alfresco Nexus repository

Run this script with:
python3 scripts/fetch_artifacts.py [<target_subdir>] [--log-level LEVEL] [--log-file FILE]

The target_subdir is the subdirectory where the artifacts yaml files are located (optional)
"""

import argparse
import logging
import netrc
import os
import shutil
import sys
import tempfile
import urllib.request
import hashlib
import yaml
import glob

# Custom exceptions
class ChecksumMismatchError(Exception):
    """
    Exception raised when the checksum of the downloaded artifact does not match the source checksum
    """

# Constants
REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
TEMP_DIR = tempfile.mkdtemp()
ACS_VERSION = os.getenv("ACS_VERSION", "25")
MAVEN_FQDN = os.getenv("MAVEN_FQDN", "nexus.alfresco.com")
MAVEN_REPO = os.getenv("MAVEN_REPO", f"https://{MAVEN_FQDN}/nexus/repository")

logger = logging.getLogger(__name__)

def setup_logging(log_level=logging.INFO, log_file=None):
    """Setup logging configuration"""
    log_format = '%(message)s'

    logger.handlers.clear()
    logger.setLevel(log_level)

    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(logging.Formatter(log_format))
    logger.addHandler(console_handler)

    if log_file:
        file_handler = logging.FileHandler(log_file)
        file_handler.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s: %(message)s'))
        logger.addHandler(file_handler)

    logger.propagate = False

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
            logger.warning(f"Failed to fetch checksum from {artifact_url}.{checksum_type}: {e}")
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

        logger.info("")

        # Check if the artifact is already present
        if os.path.isfile(artifact_final_path):
            logger.info(f"Artifact {artifact_name}-{artifact_version} already present.")
            src_checksum, computed_checksum = get_checksums(artifact_checksum, artifact_url, artifact_final_path)
            if not src_checksum and not computed_checksum:
                logger.info('No valid checksum found, skipping verification...')
                continue
            if src_checksum == computed_checksum:
                logger.info(f"Checksum matched for {artifact_name}-{artifact_version}{artifact_ext}")
                continue
            logger.info(f"Checksum mismatch for {artifact_name}-{artifact_version}{artifact_ext}. Re-downloading...")
            os.remove(artifact_final_path)

        if os.path.isfile(artifact_cache_path):
            src_checksum, computed_checksum = get_checksums(artifact_checksum, artifact_url, artifact_cache_path)
            if src_checksum == computed_checksum:
                logger.info(f"Artifact {artifact_name}-{artifact_version} already present in cache, copying...")
                shutil.copy(artifact_cache_path, artifact_final_path)
                continue
            else:
                logger.info(f"Checksum mismatch for {artifact_name}-{artifact_version}{artifact_ext}. Re-downloading...")
                os.remove(artifact_cache_path)

        # Download the artifact
        logger.info(f"Downloading {artifact_group}:{artifact_name} {artifact_version} from {artifact_baseurl}")
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
                logger.warning("Invalid or missing credentials, skipping...")
                continue
            elif e.code == 403:
                logger.warning("Forbidden access, skipping...")
                continue
            else:
                # rethrow the exception to exit with failure
                raise e

        # Move to cache and copy to final path
        shutil.move(artifact_tmp_path, artifact_cache_path)
        shutil.copy(artifact_cache_path, artifact_final_path)

def arg_is_glob_pattern(arg):
    """
    Check if the argument is a path (returns True) or a glob pattern (returns False)
    """
    if os.path.exists(arg):
        logger.debug(f"Argument '{arg}' is a valid path.")
        return False
    elif "*" in arg or "?" in arg:
        logger.debug(f"Argument '{arg}' is a glob pattern.")
        return True
    else:
        return False

def find_targets(arg):
    """
    Find all the artifacts yaml files from the given argument which can be a path or a glob pattern
    """
    if arg_is_glob_pattern(arg):
        return glob.glob(arg, recursive=True)
    else:
        if os.path.isdir(arg):
            return glob.glob(os.path.join(arg, f"**/artifacts-{ACS_VERSION}.yaml"), recursive=True)
        else:
            return [arg]

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
        logger.error(f"Error parsing .netrc file: {e}")
    return None, None

def main(target_subdir=""):
    """
    Find all the artifacts yaml files and process them
    """
    targets = find_targets(os.path.sep.join([REPO_ROOT, target_subdir]))

    for target_file in targets:
        do_parse_and_mvn_fetch(target_file)

def parse_arguments():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description="Download artifacts from Alfresco Nexus repository")
    parser.add_argument('targets', nargs='*', help='Target directories or patterns')
    parser.add_argument('--log-level', choices=['DEBUG', 'INFO', 'WARNING', 'ERROR'], default='INFO', help='Set logging level')
    parser.add_argument('--log-file', help='Log to file')
    return parser.parse_args()

if __name__ == "__main__":
    args = parse_arguments()
    log_level = getattr(logging, args.log_level.upper())
    setup_logging(log_level, args.log_file)

    username, password = get_credentials_from_netrc('nexus.alfresco.com')
    if os.getenv('NEXUS_USERNAME') and os.getenv('NEXUS_PASSWORD'):
        username = os.getenv('NEXUS_USERNAME')
        password = os.getenv('NEXUS_PASSWORD')
    if username and password:
        setup_basic_auth(username, password)

    # If no arguments provided, run with empty string (default behavior)
    if not args.targets:
        main("")
    else:
        for target_directory in args.targets:
            logger.debug(f"--- Processing target: {target_directory} ---")
            main(target_directory)
