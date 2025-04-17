ifneq ($(shell which docker-compose 2>/dev/null),)
    DOCKER_COMPOSE := docker-compose
else
    DOCKER_COMPOSE := docker compose
endif


help: 
	@echo "================================================"
	@echo "Sage.Education/AI by Startr.Cloud and Open WebUI"
	@echo "================================================"
	@echo ""
	@echo 'This is the default make command.' 
	@echo "This command lists available make commands."
	@echo ""
	@echo "Usage example:"
	@echo "    make it_run"
	@echo ""
	@echo "Available make commands:"
	@echo ""
	@LC_ALL=C $(MAKE) -pRrq -f $(firstword $(MAKEFILE_LIST)) : 2>/dev/null \
		| awk -v RS= -F: '/(^|\n)# Files(\n|$$)/,/(^|\n)# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | grep -E -v -e '^[^[:alnum:]]' -e '^$$@$$'
	@echo ""	
# Configuration variables
IMAGE_NAME := startr/ai-web-openwebui
GHCR_IMAGE_NAME := ghcr.io/$(IMAGE_NAME)
GIT_TAG := $(shell git tag --sort=-v:refname | sed 's/^v//' | head -n 1)
IMAGE_TAG := $(if $(GIT_TAG),$(GIT_TAG),latest)
GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
ifeq ($(GIT_BRANCH),HEAD)
    GIT_BRANCH := $(shell git describe --tags --exact-match 2>/dev/null || git rev-parse --short HEAD)
endif
SAFE_GIT_BRANCH := $(subst /,-,$(GIT_BRANCH))
SAFE_GIT_BRANCH := $(shell echo $(SAFE_GIT_BRANCH) | tr '[:upper:]' '[:lower:]')
CONTAINER_NAME := ai-web-openwebui
PORT_MAPPING := 8080:8080
VOLUME_DATA := sage-open-webui:/app/backend/data
ENV_FILE := $$(pwd)/.env:/app/.env
FRONTEND_SRC := $$(pwd)/src/:/app/src/


# Architectures to build for
ARCHITECTURES := amd64 arm64 # Not used at the moment

# Common docker run arguments
DOCKER_RUN_ARGS := --rm -p $(PORT_MAPPING) \
	--add-host=host.docker.internal:host-gateway \
	-v $(VOLUME_DATA) \
	-v $(ENV_FILE) \
	--name $(CONTAINER_NAME)

DEV_RUN_ARGS := --rm -p $(PORT_MAPPING) \
	--add-host=host.docker.internal:host-gateway \
	-p 5173:5173 \
	-v $(VOLUME_DATA) \
	-v $(ENV_FILE) \
	-v $(FRONTEND_SRC) \
	--name $(CONTAINER_NAME)

it_stop:
	docker rm -f $(CONTAINER_NAME)

it_clean:
	docker system prune -f
	docker builder prune --force

it_gone:
	@echo "Forcefully stopping and removing $(CONTAINER_NAME)..."
	docker stop $(CONTAINER_NAME) || true
	docker rm -f $(CONTAINER_NAME) || true
	@echo "Container $(CONTAINER_NAME) has been removed"

# Build Docker Image with Branch Name
it_build:
	@echo "Building Docker image with BuildKit enabled..."
	@export DOCKER_BUILDKIT=1 && \
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) \
	            -t $(IMAGE_NAME):latest \
	            -t $(IMAGE_NAME):$(IMAGE_TAG)-$(SAFE_GIT_BRANCH) \
	            -t $(IMAGE_NAME):$(SAFE_GIT_BRANCH) \
	            .
	afplay /System/Library/Sounds/Glass.aiff

# Build Docker Image without Cache and with Branch Name
it_build_no_cache:
	@echo "Building Docker image without cache and with BuildKit enabled..."
	@export DOCKER_BUILDKIT=1 && \
	docker build --no-cache -t $(IMAGE_NAME):$(IMAGE_TAG) \
	                     -t $(IMAGE_NAME):latest \
	                     -t $(IMAGE_NAME):$(IMAGE_TAG)-$(SAFE_GIT_BRANCH) \
	                     -t $(IMAGE_NAME):$(SAFE_GIT_BRANCH) \
	                     .
	afplay /System/Library/Sounds/Glass.aiff


build_slim:
	# Build a slim version of the image from the Dockerimage
	# Note at the moment manual use of the site is required to build the slim version
	# we need to add selenium automation to the build process to automate this
	slim build --http-probe  --include-path /app/backend --include-path /app/static --continue-after=160  $(IMAGE_NAME)

it_run_slim:
	# Run the slim version of the image
	docker run $(DOCKER_RUN_ARGS) $(IMAGE_NAME).slim:latest


dev_run:
	docker run $(DEV_RUN_ARGS) $(IMAGE_NAME):$(IMAGE_TAG) bash -c "/app/backend/restore_backup_start.sh dev" 

# Run targets
it_run:
	docker run $(DOCKER_RUN_ARGS) $(IMAGE_NAME):$(IMAGE_TAG)

# Combine build and dev run targets
it_build_n_dev_run: it_build
	afplay /System/Library/Sounds/Glass.aiff
	@make dev_run

# Combined build and run targets
it_build_n_run: it_build
	@make it_run

it_build_n_run_no_cache: it_build_no_cache
	@make it_run

# Ensure builder target
ensure_builder:
	@docker buildx inspect multi-arch-builder >/dev/null 2>&1 || docker buildx create --name multi-arch-builder --use

# Multi-architecture build helpers
define build_arch
	@make it_clean
	@make ensure_builder	
	docker buildx build --platform linux/$(1) \
		-t $(2):$(1)-$(IMAGE_TAG) \
		-t $(2):$(1)-latest \
		--build-arg ARCH=$(1) \
		--load . && \
	docker push $(2):$(1)-$(IMAGE_TAG) && \
	docker push $(2):$(1)-latest
endef

# Clean old manifests
clean-manifests-dockerhub:
	docker manifest rm $(IMAGE_NAME):$(IMAGE_TAG) || true
	docker manifest rm $(IMAGE_NAME):latest || true

clean-manifests-ghcr:
	docker manifest rm $(GHCR_IMAGE_NAME):$(IMAGE_TAG) || true
	docker manifest rm $(GHCR_IMAGE_NAME):latest || true

# Build individual architectures for Docker Hub
build-amd64-dockerhub:
	@echo "Building AMD64 for Docker Hub"
	$(call build_arch,amd64,$(IMAGE_NAME))

build-arm64-dockerhub:
	@echo "Building ARM64 for Docker Hub"
	$(call build_arch,arm64,$(IMAGE_NAME))

# Build individual architectures for GHCR
build-amd64-ghcr:
	@echo "Building AMD64 for GHCR"
	$(call build_arch,amd64,$(GHCR_IMAGE_NAME))

build-arm64-ghcr:
	@echo "Building ARM64 for GHCR"
	$(call build_arch,arm64,$(GHCR_IMAGE_NAME))

# Create and push manifests for Docker Hub
create-manifest-dockerhub: build-amd64-dockerhub build-arm64-dockerhub
	@echo "Creating Docker Hub manifests for version $(IMAGE_TAG)"
	docker manifest create \
		$(IMAGE_NAME):$(IMAGE_TAG) \
		$(IMAGE_NAME):amd64-$(IMAGE_TAG) \
		$(IMAGE_NAME):arm64-$(IMAGE_TAG)
	docker manifest push $(IMAGE_NAME):$(IMAGE_TAG)
	docker manifest create \
		$(IMAGE_NAME):latest \
		$(IMAGE_NAME):amd64-latest \
		$(IMAGE_NAME):arm64-latest
	docker manifest push $(IMAGE_NAME):latest

# Create and push manifests for GHCR
create-manifest-ghcr: build-amd64-ghcr build-arm64-ghcr
	@echo "Creating GHCR manifests for version $(IMAGE_TAG)"
	docker manifest create \
		$(GHCR_IMAGE_NAME):$(IMAGE_TAG) \
		$(GHCR_IMAGE_NAME):amd64-$(IMAGE_TAG) \
		$(GHCR_IMAGE_NAME):arm64-$(IMAGE_TAG)
	docker manifest push $(GHCR_IMAGE_NAME):$(IMAGE_TAG)
	docker manifest create \
		$(GHCR_IMAGE_NAME):latest \
		$(GHCR_IMAGE_NAME):amd64-latest \
		$(GHCR_IMAGE_NAME):arm64-latest
	docker manifest push $(GHCR_IMAGE_NAME):latest

# Bring down container instances on each SAGE_HOST
it_down_sage_hosts:
	@echo "Bringing down instances on SAGE_HOSTS from .env file..."
	@if [ -f .env ]; then \
		grep -E "^SAGE_HOSTS=" .env | cut -d '=' -f2 | tr ',' '\n' | while read host; do \
			echo "Stopping containers on $$host..."; \
			ssh "$$host" "docker stop $$(docker ps -aqf 'name=sage*') && docker rm $$(docker ps -aqf 'name=sage*')" || echo "Failed to stop containers on $$host"; \
		done; \
	else \
		echo ".env file not found. Cannot read SAGE_HOSTS."; \
		exit 1; \
	fi

# Check for running Sage instances on each SAGE_HOST
it_check_sage_hosts:
	@echo "Checking for running Sage instances on SAGE_HOSTS from .env file..."
	@if [ -f .env ]; then \
		echo "Host                 | Container ID    | Name             | Image                | Status           | Created"; \
		echo "-------------------- | --------------- | ---------------- | -------------------- | ---------------- | ---------------"; \
		grep -E "^SAGE_HOSTS=" .env | cut -d '=' -f2 | tr ',' '\n' | while read host; do \
			echo "$$host:"; \
			ssh "$$host" "docker ps --format '{{.ID}} | {{.Names}} | {{.Image}} | {{.Status}} | {{.CreatedAt}}' -f 'name=sage*'" || echo "   Failed to connect to $$host"; \
			echo ""; \
		done; \
	else \
		echo ".env file not found. Cannot read SAGE_HOSTS."; \
		exit 1; \
	fi

# Main multi-arch build targets
it_build_multi_arch_push_docker_hub: clean-manifests-dockerhub create-manifest-dockerhub
	@echo "Completed Docker Hub multi-arch build and push for version $(IMAGE_TAG)"

it_build_multi_arch_push_GHCR: clean-manifests-ghcr create-manifest-ghcr
	@echo "Completed GHCR multi-arch build and push for version $(IMAGE_TAG)"

# Build both registries
it_build_multi_arch_all: it_build_multi_arch_push_docker_hub it_build_multi_arch_push_GHCR
	@echo "Completed all multi-arch builds and pushes for version $(IMAGE_TAG)"

# Utility target to show current version
show-version:
	@echo "Current version: $(IMAGE_TAG)"

.PHONY: it_build it_build_no_cache dev_run it_run it_build_n_run it_build_n_run_no_cache \
	clean-manifests-dockerhub clean-manifests-ghcr \
	build-amd64-dockerhub build-arm64-dockerhub \
	build-amd64-ghcr build-arm64-ghcr \
	create-manifest-dockerhub create-manifest-ghcr \
	it_build_multi_arch_push_docker_hub it_build_multi_arch_push_GHCR \
	it_build_multi_arch_all show-version

it_install:
	$(DOCKER_COMPOSE) up -d



minor_release:
	# Start a minor release with incremented minor version
	git flow release start $$(git tag --sort=-v:refname | sed 's/^v//' | head -n 1 | awk -F'.' '{print $$1"."$$2+1".0"}')

patch_release:
	# Start a patch release with incremented patch version
	git flow release start $$(git tag --sort=-v:refname | sed 's/^v//' | head -n 1 | awk -F'.' '{print $$1"."$$2"."$$3+1}')

major_release:
	# Start a major release with incremented major version
	git flow release start $$(git tag --sort=-v:refname | sed 's/^v//' | head -n 1 | awk -F'.' '{print $$1+1".0.0"}')

hotfix:
	# Start a hotfix with incremented patch version
	git flow hotfix start $$(git tag --sort=-v:refname | sed 's/^v//' | head -n 1 | awk -F'.' '{print $$1"."$$2"."$$3+1}')

release_finish:
	git flow release finish "$$(git branch --show-current | sed 's/release\///')" && git push origin develop && git push origin main && git push --tags && git checkout develop

hotfix_finish:
	git flow hotfix finish "$$(git branch --show-current | sed 's/hotfix\///')" && git push origin develop && git push origin main && git push --tags && git checkout develop

things_clean:
	git clean --exclude=!.env -Xdf


it_deploy:
	caprover deploy --default

it_start:
	docker start $(CONTAINER_NAME)

it_start_and_build: it_build
	docker start $(CONTAINER_NAME)

it_update:
	@echo "Updating LLM models and rebuilding container..."
	@chmod +x update_ollama_models.sh
	@./update_ollama_models.sh
	@git pull
	docker stop $(CONTAINER_NAME) || true
	@make it_build
	@make it_run