#!/usr/bin/env bash
shopt -s extglob
set -eo pipefail

WORKING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${WORKING_DIR}/.." && pwd)"

export DOCKER_NAME=${DOCKER_NAME:-"ansible-jenkins-slave-docker"}
export DOCKER_TAG=${DOCKER_TAG:-"2.0.10"}
export DOCKER_FILE=${DOCKER_FILE:-"docker/ubuntu24/Dockerfile"}
export CST_CONFIG=${CST_CONFIG:-"docker/ubuntu24/config.yaml"}
export DOCKER_BUILD_ARGS=${DOCKER_BUILD_ARGS:-"--pull"}
export RUN_ANSIBLE_SETUP=${RUN_ANSIBLE_SETUP:-"true"}

unset ANSIBLE_VAULT_PASSWORD_FILE

bootstrap_ansible_shell_role() {
  if [[ -e "${WORKING_DIR}/docker-env.sh" && -e "${WORKING_DIR}/run-ansible.sh" ]]; then
    return 0
  fi

  if ! command -v ansible-galaxy >/dev/null 2>&1; then
    echo "ERROR: ansible-galaxy is required to bootstrap albanandrieu.shell" >&2
    return 1
  fi

  echo "Bootstrapping the albanandrieu.shell role required by scripts/*.sh symlinks"
  mkdir -p "${ROOT_DIR}/roles"
  local requirements_file
  requirements_file="$(mktemp)"
  cat >"${requirements_file}" <<'YAML'
---
- src: https://github.com/AlbanAndrieu/ansible-shell.git
  name: albanandrieu.shell
  version: master
YAML
  ansible-galaxy role install \
    -r "${requirements_file}" \
    -p "${ROOT_DIR}/roles" \
    --force
  rm -f "${requirements_file}"
}

bootstrap_ansible_shell_role

# shellcheck source=/dev/null
source "${WORKING_DIR}/docker-env.sh"

"${WORKING_DIR}/docker-validate.sh"

if [[ "${RUN_ANSIBLE_SETUP}" == "true" ]]; then
  # The historical local workflow configures/checks the workstation before the
  # Docker build. CI deliberately skips this expensive host provisioning step.
  # shellcheck source=/dev/null
  source "${WORKING_DIR}/run-ansible.sh"
else
  echo "Skipping host Ansible setup (RUN_ANSIBLE_SETUP=${RUN_ANSIBLE_SETUP})"
fi

export DOCKER_BUILDKIT=1
export BUILDKIT_STEP_LOG_MAX_SIZE=${BUILDKIT_STEP_LOG_MAX_SIZE:-20971520}
export BUILDKIT_STEP_LOG_MAX_SPEED=${BUILDKIT_STEP_LOG_MAX_SPEED:-1048576}

IMAGE_LATEST="${DOCKER_ORGANISATION}/${DOCKER_NAME}"
IMAGE_VERSIONED="${DOCKER_ORGANISATION}/${DOCKER_NAME}:${DOCKER_TAG}"

echo "Building ${IMAGE_VERSIONED} from ${DOCKER_FILE}"
# DOCKER_BUILD_ARGS intentionally remains a string for backward compatibility
# with local overrides used by this repository.
# shellcheck disable=SC2086
time docker build ${DOCKER_BUILD_ARGS} \
  -f "${ROOT_DIR}/${DOCKER_FILE}" \
  --tag "${IMAGE_LATEST}" \
  --tag "${IMAGE_VERSIONED}" \
  "${ROOT_DIR}"

echo "Docker build completed: ${IMAGE_VERSIONED}"

if [[ "${CI:-false}" == "true" ]]; then
  docker image inspect "${IMAGE_VERSIONED}" --format='{{.Id}} {{.Size}} bytes'
  exit 0
fi

echo ""
echo "This image is a trusted Docker image."
echo ""
echo "To push it:"
echo "  docker login ${DOCKER_REGISTRY:-} --username ${DOCKER_USERNAME:-}"
echo "  docker push ${IMAGE_LATEST}"
echo "  docker push ${IMAGE_VERSIONED}"
echo ""
echo "To pull it:"
echo "  docker pull ${IMAGE_VERSIONED}"
echo ""
echo "To use this Docker image:"
echo "  docker run -d -P ${IMAGE_LATEST}"
echo "  docker run --net host -d -P ${IMAGE_LATEST}"
echo ""

echo "Run CST test with:"
echo "  ${WORKING_DIR}/docker-test.sh ${DOCKER_NAME}"
echo ""
echo "Validate the repository before tagging/pushing a release."
