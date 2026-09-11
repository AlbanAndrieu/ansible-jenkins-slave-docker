#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE_NAME="${RUNNER_IMAGE_NAME:-nabla/runner-build}"
IMAGE_TAG="${RUNNER_IMAGE_TAG:-dev}"
IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"

command -v docker >/dev/null 2>&1 || {
  echo "ERROR: docker is required" >&2
  exit 1
}

docker buildx version >/dev/null 2>&1 || {
  echo "ERROR: docker buildx is required" >&2
  exit 1
}

echo "Building ${IMAGE}"
docker buildx build \
  --load \
  --file "${ROOT_DIR}/docker/runner/Dockerfile" \
  --tag "${IMAGE}" \
  "${ROOT_DIR}"

echo "Validating runner toolchain"
docker run --rm "${IMAGE}" bash -lc '
  set -euo pipefail
  . /etc/os-release
  test "${VERSION_ID}" = "24.04"
  test "$(python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")" = "3.13"
  test "$(node --version)" = "v25.9.0"
  test "$(npm --version)" = "11.17.0"
  mise --version
  uv --version
  git --version
  docker --version
  docker buildx version
  docker compose version
'

echo "Runner image smoke passed: ${IMAGE}"
