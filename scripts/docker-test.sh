#!/usr/bin/env bash
set -euo pipefail

WORKING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${WORKING_DIR}/.." && pwd)"

DOCKER_NAME="${1:-${DOCKER_NAME:-ansible-jenkins-slave-docker}}"
DOCKER_TAG="${2:-${DOCKER_TAG:-latest}}"
DOCKER_ORGANISATION="${DOCKER_ORGANISATION:-nabla}"
CST_CONFIG="${CST_CONFIG:-docker/ubuntu24/config.yaml}"
CST_VERSION="${CST_VERSION:-1.22.1}"
IMAGE="${DOCKER_ORGANISATION}/${DOCKER_NAME}:${DOCKER_TAG}"
CONFIG_PATH="${ROOT_DIR}/${CST_CONFIG}"

if [[ ! -f "${CONFIG_PATH}" ]]; then
  echo "ERROR: CST config not found: ${CONFIG_PATH}" >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker is required to run container structure tests" >&2
  exit 1
fi

docker image inspect "${IMAGE}" >/dev/null

CST_BIN="${CST_BIN:-}"
if [[ -z "${CST_BIN}" ]]; then
  CST_BIN="$(command -v container-structure-test || true)"
fi

if [[ -z "${CST_BIN}" ]]; then
  if ! command -v curl >/dev/null 2>&1; then
    echo "ERROR: curl is required to install container-structure-test" >&2
    exit 1
  fi

  CST_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/container-structure-test/${CST_VERSION}"
  CST_BIN="${CST_DIR}/container-structure-test"
  mkdir -p "${CST_DIR}"

  if [[ ! -x "${CST_BIN}" ]]; then
    echo "Installing container-structure-test v${CST_VERSION} into ${CST_DIR}"
    tmp_bin="${CST_BIN}.tmp"
    curl --fail --silent --show-error --location --retry 3 \
      "https://github.com/GoogleContainerTools/container-structure-test/releases/download/v${CST_VERSION}/container-structure-test-linux-amd64" \
      --output "${tmp_bin}"
    chmod +x "${tmp_bin}"
    mv "${tmp_bin}" "${CST_BIN}"
  fi
fi

echo "Testing ${IMAGE} with ${CST_BIN} and ${CST_CONFIG}"
"${CST_BIN}" test \
  --image "${IMAGE}" \
  --config "${CONFIG_PATH}" \
  --no-color
