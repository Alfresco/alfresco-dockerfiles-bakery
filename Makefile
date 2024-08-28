clean:
	@echo "Cleaning up Artifacts"
	@find . \( -name "*.jar" -o -name "*.zip" -o -name "*.gz" -o -name "*.tgz" -o -name  "*.rpm" -o -name "*.deb" \) -type f -delete

prepare_repo: scripts/fetch-artifacts.sh
	@echo "Fetching all artifacts for repository target"
	@./scripts/fetch-artifacts.sh repository

prepare_tengines: scripts/fetch-artifacts.sh
	@echo "Fetching all artifacts for tengines targets"
	@./scripts/fetch-artifacts.sh tengine

prepare_ats: scripts/fetch-artifacts.sh
	@echo "Fetching all artifacts for ats targets"
	@./scripts/fetch-artifacts.sh ats

prepare_search_enterprise: scripts/fetch-artifacts.sh
	@echo "Fetching all artifacts for Search Enterprise targets"
	@./scripts/fetch-artifacts.sh search/enterprise

prepare_connectors: scripts/fetch-artifacts.sh
	@echo "Fetching all artifacts for Connectors targets"
	@./scripts/fetch-artifacts.sh connector

prepare_all: scripts/fetch-artifacts.sh
	@echo "Fetching all artifacts"
	@./scripts/fetch-artifacts.sh

repo: prepare_repo
	@echo "Building repository image"
	@docker buildx bake --no-cache --progress=plain repository

tengines: prepare_tengines
	@echo "Building Transform Egnine images"
	@docker buildx bake --no-cache --progress=plain tengines

ats: prepare_ats prepare_tengines
	@echo "Building Transform Service images"
	@docker buildx bake --no-cache --progress=plain ats tengines

search_enterprise: prepare_search_enterprise
	@echo "Building Search Enterprise images"
	@docker buildx bake --no-cache --progress=plain enterprise-search

connectors: prepare_connectors
	@echo "Building Connectors images"
	@docker buildx bake --no-cache --progress=plain connectors

amd64_all: docker-bake.hcl prepare_all
	@echo "Building all images for amd64"
	@docker buildx bake --no-cache --progress=plain --set *.platform=linux/amd64

arm64_all: docker-bake.hcl prepare_all
	@echo "Building all images for arm64"
	@docker buildx bake --no-cache --progress=plain --set *.platform=linux/arm64

arm64_supported: docker-bake.hcl prepare_all
	@echo "Building all supported images for arm64"
	@export TARGET_ARCH="linux/arm64"
	@docker buildx bake --no-cache --progress=plain java_base

all: docker-bake.hcl prepare_all
	@echo "Building all images"
	@docker buildx bake --no-cache --progress=plain

all_ci: repo tengines ats search_enterprise clean connectors
	@echo "Building all images using individual targets for Continuous Integration"
