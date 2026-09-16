## This Makefile is a wrapper around the docker-bake command
## to provide support for login and push to a registry.

SHELL := /bin/bash
DOCKER_BAKE_ARGS := --progress=plain

.PHONY: all test
.PHONY: enterprise community
.PHONY: adf_apps aps ats audit_storage connectors cic_connector
.PHONY: repository search_batch_indexing search_enterprise search_liveindexing search_reindexing search_service share sync tengines
.PHONY: tengine_aio tengine_imagemagick tengine_libreoffice tengine_misc tengine_pdfrenderer tengine_tika
.PHONY: prepare prepare_adf prepare_aps prepare_ats prepare_audit_storage prepare_connectors
.PHONY: prepare_cic_connector prepare_repo prepare_search_community prepare_search_enterprise
.PHONY: prepare_search_liveindexing prepare_search_reindexing prepare_search_service prepare_share prepare_sync prepare_tengines
.PHONY: prepare_tengine_aio prepare_tengine_imagemagick prepare_tengine_libreoffice prepare_tengine_misc prepare_tengine_pdfrenderer prepare_tengine_tika
.PHONY: help setenv auth clean clean_caches grype

help:
	@echo "Usage: make <target>"
	@echo "Targets:"
	@echo "  all                 Build all images"
	@echo "  enterprise          Build enterprise images"
	@echo "  community           Build community images"
	@echo "  adf_apps            Build ADF Apps images"
	@echo "  ats                 Build Transform Service images"
	@echo "  audit_storage       Build Audit Storage images"
	@echo "  connectors          Build MS365/Teams Connectors images"
	@echo "  cic_connector       Build CIC Connector images"
	@echo "  repository          Build Repository image"
	@echo "  search_enterprise   Build Search Enterprise images"
	@echo "  search_batch_indexing Build Search Community Batch Indexing image"
	@echo "  search_service      Build Search Service images"
	@echo "  share               Build Share images"
	@echo "  sync                Build Sync Service images"
	@echo "  tengines            Build Transform Engine images"
	@echo "  aps                 Build Alfresco Process Services images"
	@echo "  ========================================================"
	@echo "  clean               Clean up Nexus artifacts"
	@echo "  clean_caches        Clean up Docker and artifact caches"
	@echo "  help                Display this help message"

ACS_VERSION ?= 26
APS_VERSION ?= 26
CUSTOMIZATION_REF ?=

CUSTOMIZATION_REPOSITORY_ARTIFACTS_FILES := overrides/repository.yaml
CUSTOMIZATION_SHARE_ARTIFACTS_FILES := overrides/share.yaml
CUSTOMIZATION_SEARCH_COMMUNITY_ARTIFACTS_FILES := overrides/search/community.yaml
CUSTOMIZATION_SEARCH_LIVEINDEXING_ARTIFACTS_FILES := overrides/search/enterprise/common.yaml overrides/search/enterprise/all-in-one.yaml
CUSTOMIZATION_SEARCH_REINDEXING_ARTIFACTS_FILES := overrides/search/enterprise/reindexing.yaml
CUSTOMIZATION_SEARCH_ARTIFACTS_FILES := $(CUSTOMIZATION_SEARCH_LIVEINDEXING_ARTIFACTS_FILES) $(CUSTOMIZATION_SEARCH_REINDEXING_ARTIFACTS_FILES)
CUSTOMIZATION_TENGINE_AIO_ARTIFACTS_FILES := overrides/tengine/aio.yaml
CUSTOMIZATION_TENGINE_IMAGEMAGICK_ARTIFACTS_FILES := overrides/tengine/imagemagick.yaml
CUSTOMIZATION_TENGINE_LIBREOFFICE_ARTIFACTS_FILES := overrides/tengine/libreoffice.yaml
CUSTOMIZATION_TENGINE_MISC_ARTIFACTS_FILES := overrides/tengine/misc.yaml
CUSTOMIZATION_TENGINE_PDFRENDERER_ARTIFACTS_FILES := overrides/tengine/pdfrenderer.yaml
CUSTOMIZATION_TENGINE_TIKA_ARTIFACTS_FILES := overrides/tengine/tika.yaml
CUSTOMIZATION_TENGINE_ARTIFACTS_FILES := $(CUSTOMIZATION_TENGINE_AIO_ARTIFACTS_FILES) $(CUSTOMIZATION_TENGINE_IMAGEMAGICK_ARTIFACTS_FILES) $(CUSTOMIZATION_TENGINE_LIBREOFFICE_ARTIFACTS_FILES) $(CUSTOMIZATION_TENGINE_MISC_ARTIFACTS_FILES) $(CUSTOMIZATION_TENGINE_PDFRENDERER_ARTIFACTS_FILES) $(CUSTOMIZATION_TENGINE_TIKA_ARTIFACTS_FILES)
CUSTOMIZATION_AUDIT_STORAGE_ARTIFACTS_FILES := overrides/audit-storage.yaml
CUSTOMIZATION_SYNC_ARTIFACTS_FILES := overrides/sync.yaml
CUSTOMIZATION_CONNECTORS_ARTIFACTS_FILES := overrides/connector/ms365.yaml overrides/connector/msteams.yaml
CUSTOMIZATION_APS_ARTIFACTS_FILES := overrides/aps/admin.yaml overrides/aps/app.yaml
CUSTOMIZATION_ATS_ARTIFACTS_FILES := overrides/ats/sfs.yaml overrides/ats/trouter.yaml
CUSTOMIZATION_CIC_CONNECTOR_ARTIFACTS_FILES := overrides/cic-connector/bulk-ingester.yaml overrides/cic-connector/live-ingester.yaml overrides/cic-connector/nucleus-sync.yaml
CUSTOMIZATION_ALL_ARTIFACTS_FILES := $(CUSTOMIZATION_REPOSITORY_ARTIFACTS_FILES) $(CUSTOMIZATION_SHARE_ARTIFACTS_FILES) $(CUSTOMIZATION_SEARCH_COMMUNITY_ARTIFACTS_FILES) $(CUSTOMIZATION_SEARCH_ARTIFACTS_FILES) $(CUSTOMIZATION_TENGINE_ARTIFACTS_FILES) $(CUSTOMIZATION_AUDIT_STORAGE_ARTIFACTS_FILES) $(CUSTOMIZATION_SYNC_ARTIFACTS_FILES) $(CUSTOMIZATION_CONNECTORS_ARTIFACTS_FILES) $(CUSTOMIZATION_APS_ARTIFACTS_FILES) $(CUSTOMIZATION_ATS_ARTIFACTS_FILES) $(CUSTOMIZATION_CIC_CONNECTOR_ARTIFACTS_FILES)

CUSTOMIZATION_ARTIFACTS_ARGS = $(if $(CUSTOMIZATION_REF),$(foreach manifest,$(CUSTOMIZATION_DEFAULT_ARTIFACTS_FILES),--override-artifacts-url https://raw.githubusercontent.com/Alfresco/alfresco-dockerfiles-bakery/$(CUSTOMIZATION_REF)/$(manifest)))
export ACS_VERSION
export APS_VERSION
export ARTIFACT_VERSIONS = $(shell python3 ./scripts/print_artifact_versions.py $(CUSTOMIZATION_ARTIFACTS_ARGS))

all prepare: CUSTOMIZATION_DEFAULT_ARTIFACTS_FILES := $(CUSTOMIZATION_ALL_ARTIFACTS_FILES)
enterprise: CUSTOMIZATION_DEFAULT_ARTIFACTS_FILES := $(CUSTOMIZATION_REPOSITORY_ARTIFACTS_FILES) $(CUSTOMIZATION_SHARE_ARTIFACTS_FILES) $(CUSTOMIZATION_SEARCH_ARTIFACTS_FILES) $(CUSTOMIZATION_TENGINE_ARTIFACTS_FILES) $(CUSTOMIZATION_AUDIT_STORAGE_ARTIFACTS_FILES) $(CUSTOMIZATION_SYNC_ARTIFACTS_FILES) $(CUSTOMIZATION_CONNECTORS_ARTIFACTS_FILES) $(CUSTOMIZATION_CIC_CONNECTOR_ARTIFACTS_FILES)
community: CUSTOMIZATION_DEFAULT_ARTIFACTS_FILES := $(CUSTOMIZATION_REPOSITORY_ARTIFACTS_FILES) $(CUSTOMIZATION_SHARE_ARTIFACTS_FILES) $(CUSTOMIZATION_SEARCH_COMMUNITY_ARTIFACTS_FILES) $(CUSTOMIZATION_TENGINE_ARTIFACTS_FILES)
repository prepare_repo: CUSTOMIZATION_DEFAULT_ARTIFACTS_FILES := $(CUSTOMIZATION_REPOSITORY_ARTIFACTS_FILES)
share prepare_share: CUSTOMIZATION_DEFAULT_ARTIFACTS_FILES := $(CUSTOMIZATION_SHARE_ARTIFACTS_FILES)
search_enterprise prepare_search_enterprise: CUSTOMIZATION_DEFAULT_ARTIFACTS_FILES := $(CUSTOMIZATION_SEARCH_ARTIFACTS_FILES)
search_batch_indexing prepare_search_community: CUSTOMIZATION_DEFAULT_ARTIFACTS_FILES := $(CUSTOMIZATION_SEARCH_COMMUNITY_ARTIFACTS_FILES)
search_liveindexing prepare_search_liveindexing: CUSTOMIZATION_DEFAULT_ARTIFACTS_FILES := $(CUSTOMIZATION_SEARCH_LIVEINDEXING_ARTIFACTS_FILES)
search_reindexing prepare_search_reindexing: CUSTOMIZATION_DEFAULT_ARTIFACTS_FILES := $(CUSTOMIZATION_SEARCH_REINDEXING_ARTIFACTS_FILES)
connectors prepare_connectors: CUSTOMIZATION_DEFAULT_ARTIFACTS_FILES := $(CUSTOMIZATION_CONNECTORS_ARTIFACTS_FILES)
aps prepare_aps: CUSTOMIZATION_DEFAULT_ARTIFACTS_FILES := $(CUSTOMIZATION_APS_ARTIFACTS_FILES)
ats prepare_ats: CUSTOMIZATION_DEFAULT_ARTIFACTS_FILES := $(CUSTOMIZATION_ATS_ARTIFACTS_FILES) $(CUSTOMIZATION_TENGINE_ARTIFACTS_FILES)
audit_storage prepare_audit_storage: CUSTOMIZATION_DEFAULT_ARTIFACTS_FILES := $(CUSTOMIZATION_AUDIT_STORAGE_ARTIFACTS_FILES)
cic_connector prepare_cic_connector: CUSTOMIZATION_DEFAULT_ARTIFACTS_FILES := $(CUSTOMIZATION_CIC_CONNECTOR_ARTIFACTS_FILES)
sync prepare_sync: CUSTOMIZATION_DEFAULT_ARTIFACTS_FILES := $(CUSTOMIZATION_SYNC_ARTIFACTS_FILES)
tengines prepare_tengines: CUSTOMIZATION_DEFAULT_ARTIFACTS_FILES := $(CUSTOMIZATION_TENGINE_ARTIFACTS_FILES)
tengine_aio prepare_tengine_aio: CUSTOMIZATION_DEFAULT_ARTIFACTS_FILES := $(CUSTOMIZATION_TENGINE_AIO_ARTIFACTS_FILES)
tengine_imagemagick prepare_tengine_imagemagick: CUSTOMIZATION_DEFAULT_ARTIFACTS_FILES := $(CUSTOMIZATION_TENGINE_IMAGEMAGICK_ARTIFACTS_FILES)
tengine_libreoffice prepare_tengine_libreoffice: CUSTOMIZATION_DEFAULT_ARTIFACTS_FILES := $(CUSTOMIZATION_TENGINE_LIBREOFFICE_ARTIFACTS_FILES)
tengine_misc prepare_tengine_misc: CUSTOMIZATION_DEFAULT_ARTIFACTS_FILES := $(CUSTOMIZATION_TENGINE_MISC_ARTIFACTS_FILES)
tengine_pdfrenderer prepare_tengine_pdfrenderer: CUSTOMIZATION_DEFAULT_ARTIFACTS_FILES := $(CUSTOMIZATION_TENGINE_PDFRENDERER_ARTIFACTS_FILES)
tengine_tika prepare_tengine_tika: CUSTOMIZATION_DEFAULT_ARTIFACTS_FILES := $(CUSTOMIZATION_TENGINE_TIKA_ARTIFACTS_FILES)

setenv: auth
ifdef BAKE_NO_CACHE
DOCKER_BAKE_ARGS += --no-cache
endif
ifdef BAKE_NO_PROVENANCE
DOCKER_BAKE_ARGS += --provenance=false
endif
	@echo "REGISTRY=$(if $(REGISTRY),$(REGISTRY),localhost) REGISTRY_NAMESPACE=$(if $(REGISTRY_NAMESPACE),$(REGISTRY_NAMESPACE),alfresco) TAG=$(if $(TAG),$(TAG),<none, tags come from artifact versions>)"

auth:
ifeq ($(REGISTRY),localhost)
	@echo "REGISTRY environment variable is set to localhost. Images will be build & loaded locally"
else ifdef REGISTRY
	@echo "Checking for REGISTRY authentication"
	@if docker login ${REGISTRY}; then \
		echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'; \
		echo "Images will be pushed to ${REGISTRY}/$${REGISTRY_NAMESPACE:-alfresco}"; \
		echo "Do make sure this location is safe to push to!"; \
		echo "In particular, make sure you are not pushing to a public registry"; \
		echo "without paying attention to the security & legal implications."; \
		echo "If you are not sure, please stop the build and check"; \
		echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'; \
		read -p "Do you want to continue? [y/N] " -n 1 -r; \
		[[ $$REPLY =~ ^[Yy]$$ ]] && echo -e '\n' || (echo -e "\nStopping build"; exit 1); \
	else \
		echo "Failed to login to ${REGISTRY}. Stopping build."; \
		exit 1; \
	fi
DOCKER_BAKE_ARGS += --set *.output=type=registry,push=true
else
	@echo "REGISTRY environment variable is not set. Images will be build & loaded locally"
endif

clean:
	@echo "Cleaning up Artifacts"
	@./scripts/clean-artifacts.sh -f

clean_caches:
	@echo "Cleaning up Docker cache"
	docker builder prune -f
	@echo "Cleaning up Artifacts cache"
	find artifacts_cache/ -mindepth 1 ! -name .gitkeep -delete

## PREPARE TARGETS
## Keep targets in alphabetical order (following the folder structure)

prepare: scripts/fetch_artifacts.py
	@echo "Fetching all artifacts"
	@python3 ./scripts/fetch_artifacts.py $(CUSTOMIZATION_ARTIFACTS_ARGS)

prepare_adf: scripts/fetch_artifacts.py
	@echo "Fetching all artifacts for ADF targets"
	@python3 ./scripts/fetch_artifacts.py adf-apps $(CUSTOMIZATION_ARTIFACTS_ARGS)

prepare_aps: scripts/fetch_artifacts.py
	@echo "Fetching all artifacts for Alfresco Process Services targets"
	@python3 ./scripts/fetch_artifacts.py "aps/**/artifacts-${APS_VERSION}.yaml" $(CUSTOMIZATION_ARTIFACTS_ARGS)

prepare_ats: scripts/fetch_artifacts.py
	@echo "Fetching all artifacts for ATS targets"
	@python3 ./scripts/fetch_artifacts.py ats $(CUSTOMIZATION_ARTIFACTS_ARGS)

prepare_audit_storage: scripts/fetch_artifacts.py
	@echo "Fetching all artifacts for Audit Storage targets"
	@python3 ./scripts/fetch_artifacts.py audit-storage $(CUSTOMIZATION_ARTIFACTS_ARGS)

prepare_connectors: scripts/fetch_artifacts.py
	@echo "Fetching all artifacts for Connector targets"
	@python3 ./scripts/fetch_artifacts.py connector $(CUSTOMIZATION_ARTIFACTS_ARGS)

prepare_cic_connector: scripts/fetch_artifacts.py
	@echo "Fetching all artifacts for CIC Connector targets"
	@python3 ./scripts/fetch_artifacts.py cic-connector $(CUSTOMIZATION_ARTIFACTS_ARGS)

prepare_repo: scripts/fetch_artifacts.py
	@echo "Fetching all artifacts for Repository target"
	@python3 ./scripts/fetch_artifacts.py repository $(CUSTOMIZATION_ARTIFACTS_ARGS)

prepare_search_community: scripts/fetch_artifacts.py
	@echo "Fetching all artifacts for Search Community (Batch Indexing) target"
	@python3 ./scripts/fetch_artifacts.py search/community $(CUSTOMIZATION_ARTIFACTS_ARGS)

prepare_search_enterprise: scripts/fetch_artifacts.py
	@echo "Fetching all artifacts for Search Enterprise targets"
	@python3 ./scripts/fetch_artifacts.py search/enterprise $(CUSTOMIZATION_ARTIFACTS_ARGS)

prepare_search_liveindexing: scripts/fetch_artifacts.py
	@echo "Fetching artifacts for Enterprise Search live indexing"
	@python3 ./scripts/fetch_artifacts.py search/enterprise/common search/enterprise/all-in-one $(CUSTOMIZATION_ARTIFACTS_ARGS)

prepare_search_reindexing: scripts/fetch_artifacts.py
	@echo "Fetching artifacts for Enterprise Search reindexing"
	@python3 ./scripts/fetch_artifacts.py search/enterprise/reindexing $(CUSTOMIZATION_ARTIFACTS_ARGS)

prepare_search_service: scripts/fetch_artifacts.py
	@echo "Fetching all artifacts for Search Service targets"
	@python3 ./scripts/fetch_artifacts.py search/service $(CUSTOMIZATION_ARTIFACTS_ARGS)

prepare_share: scripts/fetch_artifacts.py
	@echo "Fetching all artifacts for Share targets"
	@python3 ./scripts/fetch_artifacts.py share $(CUSTOMIZATION_ARTIFACTS_ARGS)

prepare_sync: scripts/fetch_artifacts.py
	@echo "Fetching all artifacts for ADF targets"
	@python3 ./scripts/fetch_artifacts.py sync $(CUSTOMIZATION_ARTIFACTS_ARGS)

prepare_tengines: scripts/fetch_artifacts.py
	@echo "Fetching all artifacts for Transform Engine targets"
	@python3 ./scripts/fetch_artifacts.py tengine $(CUSTOMIZATION_ARTIFACTS_ARGS)

prepare_tengine_aio prepare_tengine_imagemagick prepare_tengine_libreoffice prepare_tengine_misc prepare_tengine_pdfrenderer prepare_tengine_tika: scripts/fetch_artifacts.py
	@echo "Fetching artifacts for Transform Engine target $(@:prepare_%=%)"
	@python3 ./scripts/fetch_artifacts.py tengine/$(@:prepare_tengine_%=%) $(CUSTOMIZATION_ARTIFACTS_ARGS)

## BUILD TARGETS
## Keep targets in alphabetical order (following the folder structure)

all: docker-bake.hcl prepare setenv
	@echo "Building all images"
	docker buildx bake ${DOCKER_BAKE_ARGS}
	$(call grype_scan,$@)

enterprise: docker-bake.hcl prepare setenv
	@echo "Building all Enterprise images"
	docker buildx bake ${DOCKER_BAKE_ARGS} $@
	$(call grype_scan,$@)

community: docker-bake.hcl prepare setenv
	@echo "Building all Community images"
	docker buildx bake ${DOCKER_BAKE_ARGS} $@
	$(call grype_scan,$@)

adf_apps: docker-bake.hcl prepare_adf setenv
	@echo "Building ADF App images"
	docker buildx bake ${DOCKER_BAKE_ARGS} $@
	$(call grype_scan,$@)

aps: docker-bake.hcl prepare_aps setenv
	@echo "Building Alfresco Process Services images"
	docker buildx bake ${DOCKER_BAKE_ARGS} $@
	$(call grype_scan,$@)

ats: docker-bake.hcl tengines prepare_ats prepare_tengines setenv
	@echo "Building Transform Service images"
	docker buildx bake ${DOCKER_BAKE_ARGS} $@
	$(call grype_scan,$@)

audit_storage: docker-bake.hcl prepare_audit_storage setenv
	@echo "Building Audit Storage images"
	docker buildx bake ${DOCKER_BAKE_ARGS} $@
	$(call grype_scan,$@)

connectors: docker-bake.hcl prepare_connectors setenv
	@echo "Building Connector images"
	docker buildx bake ${DOCKER_BAKE_ARGS} $@
	$(call grype_scan,$@)

cic_connector: docker-bake.hcl prepare_cic_connector setenv
	@echo "Building CIC Connector components"
	docker buildx bake ${DOCKER_BAKE_ARGS} $@
	$(call grype_scan,$@)

repository: docker-bake.hcl prepare_repo setenv
	@echo "Building Repository images"
	docker buildx bake ${DOCKER_BAKE_ARGS} $@
	$(call grype_scan,$@)

search_batch_indexing: docker-bake.hcl prepare_search_community setenv
	@echo "Building Search Community Batch Indexing image"
	docker buildx bake ${DOCKER_BAKE_ARGS} $@
	$(call grype_scan,$@)

search_enterprise: docker-bake.hcl prepare_search_enterprise setenv
	@echo "Building Search Enterprise images"
	docker buildx bake ${DOCKER_BAKE_ARGS} $@
	$(call grype_scan,$@)

search_liveindexing: docker-bake.hcl prepare_search_liveindexing setenv
	@echo "Building Enterprise Search live indexing images"
	docker buildx bake ${DOCKER_BAKE_ARGS} $@
	$(call grype_scan,$@)

search_reindexing: docker-bake.hcl prepare_search_reindexing setenv
	@echo "Building Enterprise Search reindexing image"
	docker buildx bake ${DOCKER_BAKE_ARGS} $@
	$(call grype_scan,$@)

search_service: docker-bake.hcl prepare_search_service setenv
	@echo "Building Search Service images"
	docker buildx bake ${DOCKER_BAKE_ARGS} $@
	$(call grype_scan,$@)

share: docker-bake.hcl prepare_share setenv
	@echo "Building Share images"
	docker buildx bake ${DOCKER_BAKE_ARGS} $@
	$(call grype_scan,$@)

sync: docker-bake.hcl prepare_sync setenv
	@echo "Building Sync Service images"
	docker buildx bake ${DOCKER_BAKE_ARGS} $@
	$(call grype_scan,$@)

tengines: docker-bake.hcl prepare_tengines setenv
	@echo "Building Transform Engine images"
	docker buildx bake ${DOCKER_BAKE_ARGS} $@
	$(call grype_scan,$@)

tengine_aio: docker-bake.hcl prepare_tengine_aio setenv
tengine_imagemagick: docker-bake.hcl prepare_tengine_imagemagick setenv
tengine_libreoffice: docker-bake.hcl prepare_tengine_libreoffice setenv
tengine_misc: docker-bake.hcl prepare_tengine_misc setenv
tengine_pdfrenderer: docker-bake.hcl prepare_tengine_pdfrenderer setenv
tengine_tika: docker-bake.hcl prepare_tengine_tika setenv

tengine_aio tengine_imagemagick tengine_libreoffice tengine_misc tengine_pdfrenderer tengine_tika:
	@echo "Building Transform Engine image $@"
	docker buildx bake ${DOCKER_BAKE_ARGS} $@
	$(call grype_scan,$@)

GRYPE_OPTS := -f high --only-fixed --ignore-states wont-fix

define _grype_impl
	@command -v grype >/dev/null 2>&1 || { echo >&2 "grype is required but it's not installed. See https://github.com/anchore/grype/blob/main/README.md#installation"; exit 1; }
	@command -v jq >/dev/null 2>&1 || { echo >&2 "jq is required but it's not installed. See https://jqlang.org/download/"; exit 1; }
	@if [ -n "$(GRYPE_OUTPUT_DIR)" ]; then mkdir -p "$(GRYPE_OUTPUT_DIR)"; fi
	@docker buildx bake $(1) --print | jq -r '.target[] | select(.output | any(.type == "docker")) | .tags[]' \
	| while read tag; do \
		echo "Scanning image $$tag"; \
		out=/dev/stdout; \
		if [ -n "$(GRYPE_OUTPUT_DIR)" ]; then out="$(GRYPE_OUTPUT_DIR)/$$(echo "$$tag" | tr -c '[:alnum:]_.-' '_').out"; fi; \
		grype $(GRYPE_OPTS) $(if $(GRYPE_OUTPUT_FORMAT),-o $(GRYPE_OUTPUT_FORMAT)) "$$tag" > "$$out"; \
	done
endef

grype:
	@echo "Running grype scan for $(GRYPE_TARGET)"
	$(call _grype_impl,$(GRYPE_TARGET))

ifdef GRYPE_ONBUILD
define grype_scan
	@echo "Running grype scan for $(1)"
	$(call _grype_impl,$(1))
endef
endif
