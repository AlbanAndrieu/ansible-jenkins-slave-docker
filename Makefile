IMAGE_NAME := $${CI_REGISTRY_IMAGE:-"nabla/ansible-jenkins-slave-docker"}
IMAGE_TAG := $${CI_COMMIT_REF_SLUG:-"latest"}
IMAGE := $(IMAGE_NAME):$(IMAGE_TAG)

.DEFAULT_GOAL := build-docker

.PHONY: all
all: down clean build up test

.PHONY: clean
clean:
	@echo "clean"

.PHONY: build-docker
build-docker:
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

.PHONY: test
test:
	@echo "test"

.PHONY: deploy
deploy:
	@echo "deploy"
