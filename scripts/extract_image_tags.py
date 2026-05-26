"""
Extract image version tags from artifact YAML files.

Reads each component's artifacts-{ACS_VERSION}.yaml and outputs
shell export statements for per-image TAG variables consumed by
docker-bake.hcl.

Usage:
    eval $(python3 scripts/extract_image_tags.py)
"""

import os
import sys
import yaml

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
ACS_VERSION = os.getenv("ACS_VERSION", "26")
APS_VERSION = os.getenv("APS_VERSION", "26")

# env_var -> (yaml_dir, artifact_key)
IMAGE_TAG_MAP = {
    "TAG_REPOSITORY": ("repository", "alfresco-content-services-distribution"),
    "TAG_ADW": ("adf-apps/adw", "alfresco-digital-workspace"),
    "TAG_ACC": ("adf-apps/acc", "alfresco-control-center"),
    "TAG_SHARE": ("share", "alfresco-content-services-share-distribution"),
    "TAG_SYNC": ("sync", "sync-distribution"),
    "TAG_ATS_TROUTER": ("ats/trouter", "alfresco-transform-router"),
    "TAG_ATS_SFS": ("ats/sfs", "alfresco-shared-file-store-controller"),
    "TAG_TENGINE_IMAGEMAGICK": ("tengine/imagemagick", "alfresco-transform-imagemagick"),
    "TAG_TENGINE_LIBREOFFICE": ("tengine/libreoffice", "alfresco-transform-libreoffice"),
    "TAG_TENGINE_MISC": ("tengine/misc", "alfresco-transform-misc"),
    "TAG_TENGINE_TIKA": ("tengine/tika", "alfresco-transform-tika"),
    "TAG_TENGINE_PDFRENDERER": ("tengine/pdfrenderer", "alfresco-pdf-renderer-jar"),
    "TAG_TENGINE_AIO": ("tengine/aio", "alfresco-transform-core-aio"),
    "TAG_CONNECTOR_MSTEAMS": ("connector/msteams", "alfresco-ms-teams-springboot"),
    "TAG_CONNECTOR_MS365": ("connector/ms365", "onedrive-springboot"),
    "TAG_SEARCH_SERVICE": ("search/service", "alfresco-search-services"),
    "TAG_SEARCH_LIVEINDEXING": ("search/enterprise/common", "alfresco-elasticsearch-live-indexing-mediation"),
    "TAG_SEARCH_REINDEXING": ("search/enterprise/reindexing", "alfresco-elasticsearch-reindexing"),
    "TAG_AUDIT_STORAGE": ("audit-storage", "alfresco-audit-storage-app"),
    "TAG_HXINSIGHT_BULK": ("hxinsight-connector/hxinsight-connector-bulk-ingester", "alfresco-hxinsight-connector-bulk-ingester"),
    "TAG_HXINSIGHT_LIVE": ("hxinsight-connector/hxinsight-connector-live-ingester", "alfresco-hxinsight-connector-live-ingester"),
    "TAG_HXINSIGHT_PREDICTION": ("hxinsight-connector/hxinsight-connector-prediction-applier", "alfresco-hxinsight-connector-prediction-applier"),
}

APS_TAG_MAP = {
    "TAG_APS_ADMIN": ("aps/admin", "alfresco-process-services-admin"),
    "TAG_APS_APP": ("aps/app", "alfresco-process-services-app"),
}


def extract_version(yaml_dir, artifact_key, version):
    yaml_path = os.path.join(REPO_ROOT, yaml_dir, f"artifacts-{version}.yaml")
    if not os.path.exists(yaml_path):
        return None
    with open(yaml_path) as f:
        data = yaml.safe_load(f)
    artifact = data.get("artifacts", {}).get(artifact_key)
    if artifact is None:
        return None
    return artifact.get("version")


def main():
    for var_name, (yaml_dir, artifact_key) in IMAGE_TAG_MAP.items():
        version = extract_version(yaml_dir, artifact_key, ACS_VERSION)
        if version:
            print(f"export {var_name}={version}")

    for var_name, (yaml_dir, artifact_key) in APS_TAG_MAP.items():
        version = extract_version(yaml_dir, artifact_key, APS_VERSION)
        if version:
            print(f"export {var_name}={version}")


if __name__ == "__main__":
    main()
