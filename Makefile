# —— Inspired by ———————————————————————————————————————————————————————————————
# https://www.strangebuzz.com/en/snippets/the-perfect-makefile-for-symfony

# Setup ————————————————————————————————————————————————————————————————————————

# Parameters
SHELL         = bash
ME            = $(shell whoami)

# Image
DOCKER_NAME := $${CI_REGISTRY_IMAGE:-"nabla/ansible-jenkins-slave-docker"}
DOCKER_TAG := $${DOCKER_TAG:-"latest"}
DOCKER_NEXT_TAG := $${OCI_IMAGE_TAG:-"2.0.6""}
IMAGE := $(DOCKER_NAME):$(DOCKER_TAG)

TRIVY_VULN_TYPE = "os,library"
TRIVY_SECURITY_CHECKS = "vuln,config,secret"
TRIVY_GLOBAL_SECURITY_CHECKS = --security-checks ${TRIVY_SECURITY_CHECKS} --vuln-type ${TRIVY_VULN_TYPE}
TRIVY_ARGS = --skip-dirs .direnv --skip-dirs .venv --skip-dirs ./node_modules --skip-dirs /home/ubuntu/go/ --skip-dirs /home/ubuntu/node_modules/ --skip-dirs /home/runner/work/trivy/ --skip-dirs /usr/local/lib/python3.8/dist-packages/ansible/galaxy/ --skip-dirs /home/ubuntu/.local/lib/python3.8/site-packages/awscli/ --skip-dirs /home/ubuntu/.local/share/virtualenvs/ --skip-dirs /home/ubuntu/.local/lib/python3.8/site-packages/rsa/ --skip-dirs /home/ubuntu/.local/lib/python3.8/site-packages/botocore/data/ --skip-dirs /usr/lib/node_modules/ --skip-files /usr/local/bin/container-structure-test --skip-files /usr/local/go/src/crypto/elliptic/internal/fiat/Dockerfile
CS_SEVERITY_REPORT_THRESHOLD = "HIGH,CRITICAL"

# Executables: local only
DOCKER        = docker

# Misc
.DEFAULT_GOAL = build
.PHONY       =  # Not needed here, but you can put your all your targets to be sure
	            # there is no name conflict between your files and your targets.

## —— 🐝 The Strangebuzz Docker Makefile 🐝 ———————————————————————————————————
help: ## Outputs this help screen
	@grep -E '(^[a-zA-Z0-9_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

## —— All 🎵 ———————————————————————————————————————————————————————————————
.PHONY: all
all: down clean lint build up test

## —— Clean Docker 🧹🐳💩 ———————————————————————————————————————————————————————————————
.PHONY: clean-docker
clean-docker:
	@echo "=> Cleaning image..."
	docker rmi $(IMAGE)

## —— Clean 🧹 ———————————————————————————————————————————————————————————————
.PHONY: clean
clean: clean-docker
	@echo "=> Cleaning image..."
	scripts/clean.sh

## —— Lint 💍 ———————————————————————————————————————————————————————————————
.PHONY: lint
lint:
	@echo "=> Validating..."
	scripts/docker-validate.sh

## —— Docker 🐳 ————————————————————————————————————————————————————————————————
.PHONY: build-docker
build-docker:  ## Build container with docker
	@echo "=> Building image..."
	# docker build -t $(IMAGE) --build-arg CI_PIP_GITLABJUSMUNDI_TOKEN=$${CI_PIP_GITLABJUSMUNDI_TOKEN} .
	scripts/docker-build-24.sh

## —— Docker Slim 🐳 ————————————————————————————————————————————————————————————————
.PHONY: build-docker-slim
build-docker-slim:  ## Build container with docker-slim
	@echo "=> Building image..."
	@echo "docker-slim build --target $(IMAGE) --http-probe=my/sample-app"
	docker-slim build --continue-after --target $(IMAGE) --http-probe=false

## —— Buildah Docker 🐶🐳 ————————————————————————————————————————————————————————————————
.PHONY: build-buildah-docker
build-buildah-docker: ## Build container with buildah
	@echo "=> Building image..."
	buildah bud -t $(IMAGE) .

## —— Buildah 🐶 ————————————————————————————————————————————————————————————————
.PHONY: build-buildah
build-buildah: ## Build container with buildah
	@echo "=> Building image..."
	./build-oci.sh

## —— Build 🚀 —————————————————————————————————————————————————————————————————
.PHONY: build
build: build-docker

## —— Up ✅ —————————————————————————————————————————————————————————————————
.PHONY: up
up:
	@echo "up"

.PHONY: down
down:
	@echo "down"

.PHONY: run
run: down up

## —— Formating 🧪🔗 ———————————————————————————————————————————————————————————————
.PHONY: fmt
fmt: ## Run formating
	@echo "=> Executing formating..."
	shfmt -i 2 -ci -w *.sh || true
	ansible-lint --write ./

## —— Tests Ansible 🧪🔗 —————————————————————————————————————————————————————————————————
.PHONY: test
test: ## Run all tests
	@echo "=> Testing ansible..."
	ansible-lint ./

## —— Debug 📜🐳 —————————————————————————————————————————————————————————————————
.PHONY: debug
debug: ## Enter container
	@echo "=> Debuging image..."
	docker run -it -u 1000:2000 -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro -v /var/run/docker.sock:/var/run/docker.sock --entrypoint /bin/bash $(IMAGE)
	# podman run --rm -it --pod stack --user 1000:1000 -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro --name nomad $(IMAGE) /bin/bash

## —— Project 🐝🐳 ———————————————————————————————————————————————————————————————
.PHONY: exec
exec: ## Run container
	@echo "=> Executing image..."
	docker run -it -u 1000:1000 -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro -v /var/run/docker.sock:/var/run/docker.sock $(IMAGE)
  # podman run --rm -dit --pod stack --user 1000:1000 -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro --name nomad $(IMAGE)

## —— Tests Dive 🧪🐳🚨 —————————————————————————————————————————————————————————————————
.PHONY: test-dive
test-dive: ## Run Dive image tests
	@echo "=> Testing Dive image..."
	@echo "CI=true dive --ci --highestUserWastedPercent 0.1 --lowestEfficiency 0.9 --json docker-dive-stats.json $(IMAGE) 1>docker-dive.log 2>docker-dive-error.log"
	CI=true docker run --rm -it \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v  "$(pwd)":"$(pwd)" \
      -w "$(pwd)" \
      -v "$(pwd)/.dive.yaml":"$(pwd)/.dive.yaml" \
      wagoodman/dive:latest --ci --json docker-dive-stats.json $(IMAGE)

## —— Tests Dive CI 🧪🐳🚨 —————————————————————————————————————————————————————————————————
.PHONY: test-dive-ci
test-dive-ci: ## Run Dive image tests for CI
	@echo "=> Testing Dive image..."
	CI=true dive --ci --highestUserWastedPercent 0.1 --lowestEfficiency 0.9 --json docker-dive-stats.json $(IMAGE)

.PHONY: test-inspect
test-inspect:
	@echo "=> Testing image..."
	docker-inspect.sh

## —— Tests Codeclimate 🧪🤖 —————————————————————————————————————————————————————————————————
.PHONY: test-codeclimate
test-codeclimate:
	@echo "=> Testing Codeclimate image..."
	docker run \
  --interactive --tty --rm \
  --env CODECLIMATE_CODE="$PWD" \
  --volume "$PWD":/code \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --volume /tmp/cc:/tmp/cc \
  codeclimate/codeclimate analyze

## —— Tests Semgrep 🧪👽 —————————————————————————————————————————————————————————————————
.PHONY: test-semgrep
test-semgrep:
	@echo "=> Testing Semgrep image..."
	semgrep --config auto .

## —— Tests CST 🧪🕳️ —————————————————————————————————————————————————————————————————
.PHONY: test-cst
test-cst:
	@echo "=> Testing CST image..."
	@echo "/usr/local/bin/container-structure-test test --save -v info --image $(IMAGE) --config ./docker/ubuntu20/config.yaml"
	/usr/local/bin/container-structure-test test --image $(IMAGE) --config ./docker/ubuntu20/config.yaml

## —— Tests 🧪 —————————————————————————————————————————————————————————————————
.PHONY: test
test: test-dive test-codeclimate test-semgrep test-cst

## —— Tests Sast Docker 👮😈🐳 —————————————————————————————————————————————————————————————————
.PHONY: sast-docker
sast-docker:
	@echo "=> Scanning trivy image..."
	time trivy image --exit-code 1 --severity $(CS_SEVERITY_REPORT_THRESHOLD) $(TRIVY_GLOBAL_SECURITY_CHECKS) $(TRIVY_ARGS) --format table --output scan-report.md $(IMAGE) 1>docker-trivy.log 2>docker-trivy-error.log

## —— Tests Sast Fs Docker 👮😈️🐳 —————————————————————————————————————————————————————————————————
.PHONY: sast-fs-docker
sast-fs-docker:
	@echo "=> Scanning trivy filesystem..."
	time trivy filesystem --exit-code 2 --severity $(CS_SEVERITY_REPORT_THRESHOLD) $(TRIVY_GLOBAL_SECURITY_CHECKS) $(TRIVY_ARGS) --format table --output scan-report-fs.md . 1>docker-trivy-fs.log 2>docker-trivy-fs-error.log

## —— Tests Sast Buildah 👮😈🐶 —————————————————————————————————————————————————————————————————
.PHONY: sast-buildah
sast-buildah:
	@echo "=> Scanning trivy image..."
	rm -Rf "./archive/" || true
	mkdir "./archive/" || true
	buildah push $(IMAGE) docker-archive:./archive/built-with-buildah.tar:latest
	time trivy image --exit-code 1 --severity $(CS_SEVERITY_REPORT_THRESHOLD) $(TRIVY_GLOBAL_SECURITY_CHECKS) $(TRIVY_ARGS) --format table --output scan-report.md --input ./archive/built-with-buildah.tar 1>docker-trivy.log 2>docker-trivy-error.log

## —— Tests 👮😈 —————————————————————————————————————————————————————————————————
.PHONY: sast
sast: sast-fs-docker ## Run Trivy sast

## —— Deploy Docker 💾🐳 ———————————————————————————————————————————————————————————————
.PHONY: deploy-docker
deploy-docker: ## Push to registry
	@echo "=> Tagging image..."
	docker tag $(IMAGE) $(DOCKER_NAME):$(DOCKER_NEXT_TAG)
	@echo "=> docker login registry.gitlab.com"
	@echo "=> aws ecr get-login-password --region \$${AWS_REGION:-"eu-west-3"} | docker login --username AWS --password-stdin \$${OCI_REGISTRY:-\"783876277037.dkr.ecr.eu-west-3.amazonaws.com\"} "
	@echo "=> Pushing image..."
	@echo "=> By Hand 👊 => docker push $(DOCKER_NAME):$(DOCKER_NEXT_TAG)"
	@echo "=> By Hand ✌ => docker push $(DOCKER_NAME):latest"

## —— Deploy Buildah 💾🐶 ———————————————————————————————————————————————————————————————
.PHONY: deploy-buildah
deploy-buildah: ## Push to registry
	@echo "=> Tagging image..."
	buildah tag $(IMAGE) $(DOCKER_NAME):$(DOCKER_NEXT_TAG)
	@echo "=> Pushing image..."
	@echo "=> By Hand 👊 => buildah push $(DOCKER_NAME):$(DOCKER_NEXT_TAG)"
	@echo "=> By Hand ✌ => buildah push $(DOCKER_NAME):latest"

## —— Deploy 💾👑 ———————————————————————————————————————————————————————————————
.PHONY: deploy
deploy: deploy-docker ## Push to registry
