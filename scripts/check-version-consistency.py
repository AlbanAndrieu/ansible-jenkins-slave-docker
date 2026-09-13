from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SEMVER = re.compile(r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$")
TAG_SEMVER = re.compile(r"^v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$")


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


def git_output(*args: str) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip()


def main() -> int:
    failures: list[str] = []
    package = json.loads(read("package.json"))
    baseline = json.loads(read("config/release-baseline.json"))
    version = package.get("version", "")

    try:
        current_version = version_tuple(version)
        release_floor = version_tuple(baseline["semantic_release_floor"])
        major, minor, _patch = current_version
    except (KeyError, ValueError) as exc:
        print(f"❌ VERSION_CONTRACT: {exc}", file=sys.stderr)
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

    legacy_tag = baseline.get("legacy_tag", "")
    legacy_commit = baseline.get("legacy_tag_commit", "")
    if not legacy_tag or not legacy_commit:
        failures.append("config/release-baseline.json must define legacy_tag and legacy_tag_commit")
    else:
        try:
            observed_commit = git_output("rev-list", "-n", "1", legacy_tag)
        except subprocess.CalledProcessError:
            observed_commit = ""
        if observed_commit != legacy_commit:
            failures.append(
                f"{legacy_tag} must resolve to recorded legacy commit {legacy_commit}, "
                f"found {observed_commit or 'missing'}"
            )

    tagged_versions: list[tuple[int, int, int]] = []
    try:
        tags = git_output("tag", "--list", "v*").splitlines()
    except subprocess.CalledProcessError as exc:
        failures.append(f"unable to inspect Git tags: {exc}")
        tags = []

    for tag in tags:
        match = TAG_SEMVER.fullmatch(tag)
        if match:
            tagged_versions.append(tuple(int(part) for part in match.groups()))

    latest_tag = max(tagged_versions, default=(0, 0, 0))
    if latest_tag < release_floor:
        failures.append(
            "latest semantic-version tag is below configured release floor "
            f"{baseline['semantic_release_floor']}"
        )

    release_threshold = max(current_version, release_floor, latest_tag)
    todo_versions = re.findall(
        r"^## \[(\d+\.\d+\.\d+)\] - TODO\s*$", changelog, flags=re.MULTILINE
    )
    active_pending: list[str] = []
    for pending in todo_versions:
        try:
            if version_tuple(pending) > release_threshold:
                active_pending.append(pending)
        except ValueError as exc:
            failures.append(f"CHANGELOG.md {exc}")

    if len(active_pending) > 1:
        failures.append(
            "CHANGELOG.md has multiple future TODO versions above the release floor: "
            + ", ".join(active_pending)
        )

    for label, (actual, expected) in expected_values.items():
        if actual != expected:
            failures.append(f"{label}: expected {expected!r}, found {actual!r}")

    if failures:
        print("❌ VERSION_CONTRACT", file=sys.stderr)
        for failure in failures:
            print(f"- {failure}", file=sys.stderr)
        return 1

    latest_tag_text = ".".join(str(part) for part in latest_tag)
    pending = active_pending[0] if active_pending else "none"
    print(
        "✅ version contract: "
        f"source={version} release_floor={baseline['semantic_release_floor']} "
        f"latest_tag=v{latest_tag_text} next_todo={pending}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
