"""
Process artifacts yml files to download the artifacts from Maven repositories.

Each artifact declares a `source` that must be defined in sources.yaml. A source
is the root URL of a Maven repository; artifacts are fetched from it using the
standard Maven GAV layout. Credentials are resolved per source, by host, from
the standard ~/.netrc file (anonymous access is used when no entry matches).

Run this script with:
python3 scripts/fetch_artifacts.py [<target_subdir>] [--log-level LEVEL] [--log-file FILE]

The target_subdir is the subdirectory where the artifacts yaml files are located (optional)
"""

import argparse
import base64
import logging
import netrc
import os
import re
import shutil
import sys
import tempfile
import urllib.parse
import urllib.request
import hashlib
import yaml
import glob

# Custom exceptions
class ChecksumMismatchError(Exception):
    """
    Exception raised when the checksum of the downloaded artifact does not match the source checksum
    """

class SourceConfigError(Exception):
    """
    Exception raised when an artifact references a missing/unknown source or still
    carries the removed `repository` field.
    """

# Constants
REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
TEMP_DIR = tempfile.mkdtemp()
FETCHED_ARTIFACTS = set()
ACS_VERSION = os.getenv("ACS_VERSION", "26")
SOURCES_FILE = os.getenv("SOURCES_FILE", os.path.join(REPO_ROOT, "sources.yaml"))
# Host for which the NEXUS_USERNAME/NEXUS_PASSWORD environment variables act as a
# credentials override; other hosts always resolve credentials from ~/.netrc.
NEXUS_HOST = os.getenv("MAVEN_FQDN", "nexus.alfresco.com")

# Populated by load_sources(); maps a source name to its resolved configuration.
SOURCES = {}
# Artifacts skipped because of an authentication failure (reported at the end).
SKIPPED_ARTIFACTS = []

logger = logging.getLogger(__name__)

def setup_logging(log_level=logging.INFO, log_file=None):
    """Setup logging configuration"""
    log_format_debug = '%(asctime)s - %(levelname)s: %(message)s'

    if log_level is logging.DEBUG:
        log_format = log_format_debug
    else:
        log_format = '%(message)s'

    logger.handlers.clear()
    logger.setLevel(log_level)

    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(logging.Formatter(log_format))
    logger.addHandler(console_handler)

    if log_file:
        file_handler = logging.FileHandler(log_file)
        file_handler.setFormatter(logging.Formatter(log_format_debug))
        logger.addHandler(file_handler)

    logger.propagate = False

def get_credentials_from_netrc(machine):
    """
    Get credentials from .netrc for the exact machine entry.

    netrc.authenticators() falls back to the special `default` entry when there
    is no exact match; we deliberately read `hosts[machine]` instead so a default
    credential is never sent to an unrelated source host.
    """
    try:
        netrc_file = netrc.netrc()
        auth_info = netrc_file.hosts.get(machine)
        if auth_info:
            login, _, password = auth_info
            return login, password
    except FileNotFoundError:
        # Ignore if .netrc file is not found
        pass
    except netrc.NetrcParseError as e:
        logger.error(f"Error parsing .netrc file: {e}")
    return None, None

def resolve_source_credentials(host):
    """
    Resolve the credentials for a given host from ~/.netrc, honouring the
    NEXUS_USERNAME/NEXUS_PASSWORD override for the Nexus host only. Returns
    (None, None) for anonymous access.
    """
    username, password = get_credentials_from_netrc(host)
    if host == NEXUS_HOST and os.getenv("NEXUS_USERNAME") and os.getenv("NEXUS_PASSWORD"):
        username = os.getenv("NEXUS_USERNAME")
        password = os.getenv("NEXUS_PASSWORD")
    return username, password

def load_sources():
    """
    Load and resolve every source defined in sources.yaml. Credentials are
    resolved per source, by host, so each source carries only its own.
    """
    if not os.path.isfile(SOURCES_FILE):
        logger.error(f"Sources file not found: {SOURCES_FILE}")
        sys.exit(1)

    with open(SOURCES_FILE, "r", encoding="utf-8") as sources_file:
        data = yaml.safe_load(sources_file) or {}

    sources = data.get("sources")
    if not sources:
        logger.error(f"No sources defined in {SOURCES_FILE}")
        sys.exit(1)

    resolved = {}
    for name, spec in sources.items():
        url = (spec or {}).get("url")
        if not url:
            logger.error(f"Source '{name}' has no 'url' defined in {SOURCES_FILE}")
            sys.exit(1)
        url = url.rstrip("/")
        host = urllib.parse.urlsplit(url).hostname
        username, password = resolve_source_credentials(host)
        resolved[name] = {
            "name": name,
            "url": url,
            "host": host,
            "username": username,
            "password": password,
        }
        logger.debug(f"Loaded source '{name}' -> {url} ({'authenticated' if username else 'anonymous'})")

    return resolved

def resolve_artifact_source(artifact_details):
    """
    Return the resolved source for an artifact, failing fast when the artifact
    still uses the removed `repository` field or references a missing/unknown
    source.
    """
    artifact_name = artifact_details.get("name")

    if "repository" in artifact_details:
        raise SourceConfigError(
            f"Artifact '{artifact_name}' uses the removed 'repository' field; "
            f"replace it with a 'source' defined in {SOURCES_FILE}"
        )

    source_name = artifact_details.get("source")
    if not source_name:
        raise SourceConfigError(
            f"Artifact '{artifact_name}' has no 'source'; "
            f"declare one defined in {SOURCES_FILE}"
        )

    if source_name not in SOURCES:
        raise SourceConfigError(
            f"Artifact '{artifact_name}' references unknown source '{source_name}'; "
            f"define it in {SOURCES_FILE} (known sources: {', '.join(sorted(SOURCES)) or 'none'})"
        )

    return SOURCES[source_name]

def build_request(url, source):
    """
    Build an HTTP request for a URL, attaching this source's credentials (and no
    other source's) as a preemptive Basic auth header. Anonymous when the source
    has no credentials.
    """
    request = urllib.request.Request(url)
    username = source.get("username")
    password = source.get("password")
    if username and password:
        token = base64.b64encode(f"{username}:{password}".encode("utf-8")).decode("ascii")
        request.add_header("Authorization", f"Basic {token}")
    return request

def artifact_url(artifact_details, source):
    """
    Build the full download URL for an artifact from its source's base URL using
    the standard Maven GAV layout.
    """
    artifact_group = artifact_details.get("group")
    artifact_name = artifact_details.get("name")
    artifact_version = artifact_details.get("version")
    artifact_basename = artifact_filename(artifact_details)
    return (
        f"{source['url']}/{artifact_group.replace('.', '/')}"
        f"/{artifact_name}/{artifact_version}/{artifact_basename}"
    )

def get_checksums(artifact_checksum, artifact_url, artifact_file_path, source):
    """
    Get source checksum that must match and the computed checksum
    """
    if artifact_checksum and artifact_checksum.split(":")[0] in ["md5", "sha1", "sha256", "sha512"]:
        checksum_type = artifact_checksum.split(":")[0]
    else:
        return None, None
    if not artifact_checksum.split(":")[1]:
        try:
            with urllib.request.urlopen(build_request(f"{artifact_url}.{checksum_type}", source)) as checksum_response:
                checksum = checksum_response.read().decode("utf-8").strip()
        except urllib.error.HTTPError as e:
            logger.warning(f"Failed to fetch checksum from {artifact_url}.{checksum_type}: {e}")
            return None, None
    else:
        checksum = artifact_checksum.split(":")[1]
    with open(artifact_file_path, "rb") as artifact_file:
        computed_checksum = hashlib.new(checksum_type, artifact_file.read()).hexdigest()
    return checksum, computed_checksum


def artifact_filename(artifact_details):
    """
    Build the versioned file name for an artifact, e.g. postgresql-42.7.10.jar
    """
    artifact_name = artifact_details.get("name")
    artifact_version = artifact_details.get("version")
    artifact_ext = artifact_details.get("classifier", "")
    return f"{artifact_name}-{artifact_version}{artifact_ext}"

def prune_stale_artifacts(artifact_details, current_final_path):
    """
    Remove previously downloaded versions of this artifact from its target folder
    """
    artifact_dir = artifact_details.get("path")
    if not os.path.isdir(artifact_dir):
        return

    artifact_name = artifact_details.get("name")
    artifact_ext = artifact_details.get("classifier", "")
    current_basename = os.path.basename(current_final_path)
    # the version segment must start with a digit, so name prefixes like
    # alfresco-elasticsearch-live-indexing vs -content/-metadata/... don't collide
    pattern = re.compile(re.escape(artifact_name) + r"-\d[^" + re.escape(os.sep) + r"]*" + re.escape(artifact_ext))

    for entry in os.listdir(artifact_dir):
        entry_path = os.path.join(artifact_dir, entry)
        if entry == current_basename or entry_path in FETCHED_ARTIFACTS:
            continue
        if os.path.isfile(entry_path) and pattern.fullmatch(entry):
            os.remove(entry_path)
            logger.info(f"Removing stale artifact {entry_path} (superseded by {current_basename})")

def fetch_artifact(artifact_details):
    """
    Download a single artifact from its source's Maven repository, using the
    per-source cache when possible. Returns True if the wanted version ends up at
    its final path, False if the fetch was skipped (authentication failure).
    """
    source = resolve_artifact_source(artifact_details)

    artifact_name = artifact_details.get("name")
    artifact_version = artifact_details.get("version")
    artifact_checksum = artifact_details.get("checksum")
    artifact_group = artifact_details.get("group")
    artifact_path = artifact_details.get("path")

    artifact_basename = artifact_filename(artifact_details)
    artifact_tmp_path = os.path.join(TEMP_DIR, artifact_basename)
    artifact_cache_path = os.path.join(REPO_ROOT, "artifacts_cache", source["name"], artifact_basename)
    artifact_final_path = os.path.join(artifact_path, artifact_basename)
    artifact_download_url = artifact_url(artifact_details, source)

    os.makedirs(os.path.dirname(artifact_cache_path), exist_ok=True)

    # Check if the artifact is already present
    if os.path.isfile(artifact_final_path):
        logger.info(f"Artifact {artifact_name}-{artifact_version} already present.")
        src_checksum, computed_checksum = get_checksums(artifact_checksum, artifact_download_url, artifact_final_path, source)
        if not src_checksum and not computed_checksum:
            logger.info('No valid checksum found, skipping verification...')
            return True
        if src_checksum == computed_checksum:
            logger.info(f"Checksum matched for {artifact_basename}")
            return True
        logger.info(f"Checksum mismatch for {artifact_basename}. Re-downloading...")
        os.remove(artifact_final_path)

    if os.path.isfile(artifact_cache_path):
        src_checksum, computed_checksum = get_checksums(artifact_checksum, artifact_download_url, artifact_cache_path, source)
        if src_checksum == computed_checksum:
            logger.info(f"Artifact {artifact_name}-{artifact_version} already present in cache, copying...")
            shutil.copy(artifact_cache_path, artifact_final_path)
            return True
        else:
            logger.info(f"Checksum mismatch for {artifact_basename}. Re-downloading...")
            os.remove(artifact_cache_path)

    # Download the artifact
    logger.info(f"Downloading {artifact_group}:{artifact_name} {artifact_version} from {source['url']}")
    try:
        with urllib.request.urlopen(build_request(artifact_download_url, source)) as response, open(artifact_tmp_path, 'wb') as out_file:
            shutil.copyfileobj(response, out_file)

        checksums = get_checksums(
            artifact_checksum, artifact_download_url,
            artifact_tmp_path, source
        )
        if checksums[0] != checksums[1]:
            raise ChecksumMismatchError(
                f"Checksum mismatch for {artifact_basename}."
                f"Expected: {checksums[0]}, Computed: {checksums[1]}"
            )

    except urllib.error.HTTPError as e:
        if e.code in (401, 403):
            reason = "Invalid or missing credentials" if e.code == 401 else "Forbidden access"
            logger.warning(f"{reason} for {artifact_name}-{artifact_version} from source '{source['name']}', skipping...")
            SKIPPED_ARTIFACTS.append({
                "name": artifact_name,
                "version": artifact_version,
                "source": source["name"],
                "url": artifact_download_url,
                "code": e.code,
            })
            return False
        else:
            # rethrow the exception to exit with failure
            raise e

    # Move to cache and copy to final path
    shutil.move(artifact_tmp_path, artifact_cache_path)
    shutil.copy(artifact_cache_path, artifact_final_path)
    return True

def do_parse_and_mvn_fetch(file_path):
    """
    Parse the artifacts yaml file and download the artifacts from their sources
    """
    with open(file_path, "r", encoding="utf-8") as yaml_file:
        data = yaml.safe_load(yaml_file)
        artifacts = data.get("artifacts", {})

    for artifact_details in artifacts.values():
        logger.info("")
        if fetch_artifact(artifact_details):
            artifact_final_path = os.path.join(artifact_details.get("path"), artifact_filename(artifact_details))
            prune_stale_artifacts(artifact_details, artifact_final_path)
            FETCHED_ARTIFACTS.add(artifact_final_path)

def print_skipped_summary():
    """
    Report every artifact skipped because of an authentication failure.
    """
    if not SKIPPED_ARTIFACTS:
        return
    logger.warning("")
    logger.warning(f"Skipped {len(SKIPPED_ARTIFACTS)} artifact(s) due to authentication failures:")
    for skipped in SKIPPED_ARTIFACTS:
        logger.warning(
            f"  - {skipped['name']}-{skipped['version']} "
            f"(source '{skipped['source']}', HTTP {skipped['code']}): {skipped['url']}"
        )

def arg_is_glob_pattern(arg):
    """
    Check if the argument is a path (returns False) or a glob pattern (returns True)
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

def main(target_subdir=""):
    """
    Find all the artifacts yaml files and process them
    """
    targets = find_targets(os.path.sep.join([REPO_ROOT, target_subdir]))

    for target_file in targets:
        do_parse_and_mvn_fetch(target_file)

def parse_arguments():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description="Download artifacts from Maven repositories")
    parser.add_argument('targets', nargs='*', help='Target directories or patterns')
    parser.add_argument('--log-level', choices=['DEBUG', 'INFO', 'WARNING', 'ERROR'], default='INFO', help='Set logging level')
    parser.add_argument('--log-file', help='Log to file')
    return parser.parse_args()

if __name__ == "__main__":
    args = parse_arguments()
    log_level = getattr(logging, args.log_level.upper())
    setup_logging(log_level, args.log_file)

    SOURCES = load_sources()

    try:
        if not args.targets:
            main("")
        else:
            for target_directory in args.targets:
                logger.debug(f"--- Processing target: {target_directory} ---")
                main(target_directory)
    except SourceConfigError as e:
        logger.error(str(e))
        sys.exit(1)

    print_skipped_summary()
