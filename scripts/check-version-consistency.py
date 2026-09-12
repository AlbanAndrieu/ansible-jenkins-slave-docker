from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SEMVER = re.compile(r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$")


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def capture(path: str, pattern: str, label: str) -> str:
    match = re.search(pattern, read(path), flags=re.MULTILINE)
    if not match:
        raise ValueError(f"{label}: expected version expression not found in {path}")
    return match.group(1)


def version_tuple(value: str) -> tuple[int, int, int]:
    match = SEMVER.fullmatch(value)
    if not match:
        raise ValueError(f"invalid semantic version: {value!r}")
    return tuple(int(part) for part in match.groups())


def main() -> int:
    failures: list[str] = []
    package = json.loads(read("package.json"))
    version = package.get("version", "")

    try:
        current_version = version_tuple(version)
        major, minor, _patch = current_version
    except ValueError as exc:
        print(f"❌ VERSION_CONTRACT: package.json {exc}", file=sys.stderr)
        return 1

    expected_values = {
        "package.json branchVersion": (package.get("branchVersion"), f"^{version}"),
        "package.json branchPattern": (package.get("branchPattern"), f"{major}.{minor}.*"),
    }

    captures = {
        "scripts/docker-build-24.sh DOCKER_TAG": (
            "scripts/docker-build-24.sh",
            r'^export DOCKER_TAG=\$\{DOCKER_TAG:-"([^"]+)"\}$',
        ),
        "Makefile DOCKER_NEXT_TAG": (
            "Makefile",
            r'^DOCKER_NEXT_TAG := \$\$\{OCI_IMAGE_TAG:-"([^"]+)"\}$',
        ),
        "docker/ubuntu24/Dockerfile label": (
            "docker/ubuntu24/Dockerfile",
            r'^LABEL .*\bversion="([^"]+)"',
        ),
    }

    for label, (path, pattern) in captures.items():
        try:
            actual = capture(path, pattern, label)
        except ValueError as exc:
            failures.append(str(exc))
            continue
        expected_values[label] = (actual, version)

    changelog = read("CHANGELOG.md")
    if not re.search(rf"^## \[{re.escape(version)}\] - ", changelog, flags=re.MULTILINE):
        failures.append(f"CHANGELOG.md has no released section for {version}")

    todo_versions = re.findall(
        r"^## \[(\d+\.\d+\.\d+)\] - TODO\s*$", changelog, flags=re.MULTILINE
    )
    active_pending: list[str] = []
    for pending in todo_versions:
        try:
            if version_tuple(pending) > current_version:
                active_pending.append(pending)
        except ValueError as exc:
            failures.append(f"CHANGELOG.md {exc}")

    if len(active_pending) > 1:
        failures.append(
            "CHANGELOG.md has multiple future TODO versions: " + ", ".join(active_pending)
        )

    for label, (actual, expected) in expected_values.items():
        if actual != expected:
            failures.append(f"{label}: expected {expected!r}, found {actual!r}")

    if failures:
        print("❌ VERSION_CONTRACT", file=sys.stderr)
        for failure in failures:
            print(f"- {failure}", file=sys.stderr)
        return 1

    pending = active_pending[0] if active_pending else "none"
    print(f"✅ version contract: current={version} next_todo={pending}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
