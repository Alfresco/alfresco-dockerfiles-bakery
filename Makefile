SHELL := /bin/bash
DOCKER_BAKE_ARGS := --progress=plain

setenv:
ifdef REGISTRY
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
	@echo "REGISTRY is not set. Images will be build & loaded locally"
endif
ifdef BAKE_NO_CACHE
DOCKER_BAKE_ARGS += --no-cache
endif
ifdef BAKE_NO_PROVENANCE
DOCKER_BAKE_ARGS += --provenance=false
endif

clean:
	@echo "Cleaning up Artifacts"
	@find . \( -name "*.jar" -o -name "*.zip" -o -name "*.gz" -o -name "*.tgz" -o -name  "*.rpm" -o -name "*.deb" -o -name "*.amp" \) -type f -delete

prepare_repo: scripts/fetch-artifacts.sh setenv
	@echo "Fetching all artifacts for repository target"
	@./scripts/fetch-artifacts.sh repository

prepare_tengines: scripts/fetch-artifacts.sh setenv
	@echo "Fetching all artifacts for tengines targets"
	@./scripts/fetch-artifacts.sh tengine

prepare_ats: scripts/fetch-artifacts.sh setenv
	@echo "Fetching all artifacts for ats targets"
	@./scripts/fetch-artifacts.sh ats

prepare_search_enterprise: scripts/fetch-artifacts.sh setenv
	@echo "Fetching all artifacts for Search Enterprise targets"
	@./scripts/fetch-artifacts.sh search/enterprise

prepare_connectors: scripts/fetch-artifacts.sh setenv
	@echo "Fetching all artifacts for Connectors targets"
	@./scripts/fetch-artifacts.sh connector

prepare_share: scripts/fetch-artifacts.sh setenv
	@echo "Fetching all artifacts for Share targets"
	@./scripts/fetch-artifacts.sh share

prepare_adf: scripts/fetch-artifacts.sh setenv
	@echo "Fetching all artifacts for ADF targets"
	@./scripts/fetch-artifacts.sh adf-apps

prepare_all: scripts/fetch-artifacts.sh setenv
	@echo "Fetching all artifacts"
	@./scripts/fetch-artifacts.sh

repo: prepare_repo
	@echo "Building repository image"
	docker buildx bake ${DOCKER_BAKE_ARGS} repository

tengines: prepare_tengines
	@echo "Building Transform Egnine images"
	docker buildx bake ${DOCKER_BAKE_ARGS} tengines

ats: prepare_ats prepare_tengines
	@echo "Building Transform Service images"
	docker buildx bake ${DOCKER_BAKE_ARGS} ats tengines

search_enterprise: prepare_search_enterprise
	@echo "Building Search Enterprise images"
	docker buildx bake ${DOCKER_BAKE_ARGS} enterprise-search

connectors: prepare_connectors
	@echo "Building Connectors images"
	docker buildx bake ${DOCKER_BAKE_ARGS} connectors

share: prepare_share
	@echo "Building Share images"
	docker buildx bake ${DOCKER_BAKE_ARGS} share

adf_apps: prepare_adf
	@echo "Building ADF Apps images"
	docker buildx bake ${DOCKER_BAKE_ARGS} adf_apps

all: docker-bake.hcl prepare_all
	@echo "Building all images"
	docker buildx bake ${DOCKER_BAKE_ARGS}

all_ci: repo tengines ats search_enterprise clean connectors share adf_apps
	@echo "Building all images using individual targets for Continuous Integration"
