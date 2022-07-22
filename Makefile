# —— Inspired by ———————————————————————————————————————————————————————————————
# https://www.strangebuzz.com/en/snippets/the-perfect-makefile-for-symfony

# Setup ————————————————————————————————————————————————————————————————————————

# Parameters
SHELL         = bash
ME            = $(shell whoami)

# Image
DOCKER_NAME := $${CI_REGISTRY_IMAGE:-"nabla/ansible-jenkins-slave-docker"}
DOCKER_TAG := $${DOCKER_TAG:-"latest"}
DOCKER_NEXT_TAG := $${CI_COMMIT_REF_SLUG:-"2.0.3"}
IMAGE := $(DOCKER_NAME):$(DOCKER_TAG)

# Executables: local only
DOCKER        = docker

# Misc
#.DEFAULT_GOAL = help
.DEFAULT_GOAL = build-docker
.PHONY       =  # Not needed here, but you can put your all your targets to be sure
	            # there is no name conflict between your files and your targets.

## —— 🐝 The Strangebuzz Docker Makefile 🐝 ———————————————————————————————————
help: ## Outputs this help screen
	@grep -E '(^[a-zA-Z0-9_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

## —— All 🎵 ———————————————————————————————————————————————————————————————
.PHONY: all
all: down clean lint build up dive

.PHONY: rm
rm: clean
	@echo "=> Removing image..."
	docker rmi $(IMAGE)

.PHONY: clean
clean:
	@echo "=> Cleaning image..."
	scripts/clean.sh

.PHONY: lint
lint:
	@echo "=> Validating..."
	scripts/docker-validate.sh

## —— Docker 🐳 ————————————————————————————————————————————————————————————————
.PHONY: build-docker
build-docker:  ## Build container with docker
	@echo "=> Building image..."
	# docker build -t $(IMAGE) --squash .
	scripts/docker-build-20.sh

.PHONY: build-buildah-docker
build-buildah-docker:
	@echo "=> Building image..."
	buildah bud -t $(IMAGE) .

.PHONY: build
build:
	@echo "=> Building image..."
	./build-oci.sh

.PHONY: up
up:
	@echo "up"

.PHONY: down
down:
	@echo "down"

.PHONY: run
run: down up

## —— Debug 📜 —————————————————————————————————————————————————————————————————
.PHONY: debug
debug: ## Enter container
	@echo "=> Debuging image..."
	docker run -it -u 1000:2000 -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro -v /var/run/docker.sock:/var/run/docker.sock --entrypoint /bin/bash $(IMAGE)

## —— Project 🐝 ———————————————————————————————————————————————————————————————
.PHONY: exec
exec: ## Run container
	@echo "=> Executing image..."
	docker run -it -u 1000:1000 -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro -v /var/run/docker.sock:/var/run/docker.sock $(IMAGE)

.PHONY: dive
dive:
	@echo "=> Diving image..."
	CI=true dive --ci --json docker-dive-stats.json  $(IMAGE) 1>docker-dive.log 2>docker-dive-error.log

## —— Tests ✅ —————————————————————————————————————————————————————————————————
.PHONY: test
test: ## Run all tests
	@echo "=> Testing image..."
	docker-inspect.sh

## —— Deploy 💾 ———————————————————————————————————————————————————————————————
.PHONY: deploy
deploy: ## Push to registry
	@echo "=> Tagging image..."
	docker tag $(IMAGE) $(IMAGE_NAME):$(IMAGE_NEXT_TAG)
	@echo "=> Pushing image..."
	@echo "=> TODO => docker push $(IMAGE_NAME):$(IMAGE_NEXT_TAG)"
