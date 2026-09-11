#!/usr/bin/env bash
set -euo pipefail

command -v pre-commit >/dev/null 2>&1 || {
	echo "❌ pre-commit is required before installing repository hooks" >&2
	exit 1
}

ROOT="$(git rev-parse --show-toplevel)"
cd "${ROOT}"

pre-commit install --hook-type pre-commit --config .pre-commit-config.yaml
pre-commit install --hook-type pre-push --config .pre-commit-pre-push.yaml

echo "✅ pre-commit and publication pre-push hooks installed"
