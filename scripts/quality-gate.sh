#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "${ROOT}"

MODE="check"
case "${1:-}" in
--preflight)
  MODE="preflight"
  shift
  ;;
--publish)
  MODE="publish"
  shift
  ;;
-h | --help)
  cat <<'USAGE'
Usage:
  bash scripts/quality-gate.sh [--preflight|--publish]

Modes:
  default      canonical formatter/linter validation on changed files
  --preflight  dependency-free Git/workflow/syntax checks
  --publish    canonical validation used by the agent publication gate

Environment:
  QUALITY_BASE_REF  override comparison base
  QUALITY_LOG_TAIL  failure log lines to print (default: 50, capped at 100)
USAGE
  exit 0
  ;;
"") ;;
*)
  printf '❌ unknown argument: %s\n' "$1" >&2
  exit 2
  ;;
esac

if (($# > 0)); then
  printf '❌ unexpected argument: %s\n' "$1" >&2
  exit 2
fi

LOG_TAIL="${QUALITY_LOG_TAIL:-50}"
if ((LOG_TAIL > 100)); then
  LOG_TAIL=100
fi

resolve_base_ref() {
  if [[ -n "${QUALITY_BASE_REF:-}" ]]; then
    printf '%s\n' "${QUALITY_BASE_REF}"
  elif git symbolic-ref --quiet refs/remotes/origin/HEAD >/dev/null 2>&1; then
    git symbolic-ref --quiet --short refs/remotes/origin/HEAD
  elif git rev-parse --verify origin/master >/dev/null 2>&1; then
    printf '%s\n' "origin/master"
  elif git rev-parse --verify HEAD~1 >/dev/null 2>&1; then
    printf '%s\n' "HEAD~1"
  else
    printf '%s\n' "HEAD"
  fi
}

BASE_REF="$(resolve_base_ref)"

collect_changed_files() {
  {
    if [[ "${BASE_REF}" != "HEAD" ]] && git rev-parse --verify "${BASE_REF}^{commit}" >/dev/null 2>&1; then
      git diff --name-only --diff-filter=ACMR "${BASE_REF}...HEAD"
    fi
    git diff --name-only --diff-filter=ACMR
    git diff --cached --name-only --diff-filter=ACMR
    git ls-files --others --exclude-standard
  } |
    awk 'NF' |
    sort -u |
    while IFS= read -r file; do
      [[ -f "${file}" ]] && printf '%s\n' "${file}"
    done
}

mapfile -t CHANGED_FILES < <(collect_changed_files)

worktree_fingerprint() {
  {
    git diff --no-ext-diff --binary
    git diff --cached --no-ext-diff --binary
    while IFS= read -r file; do
      printf '%s\n' "${file}"
      git hash-object -- "${file}"
    done < <(git ls-files --others --exclude-standard | sort)
  } | git hash-object --stdin
}

run_compact() {
  local label="$1"
  shift
  local log rc
  log="$(mktemp)"
  if "$@" >"${log}" 2>&1; then
    rm -f "${log}"
    printf '✅ %s\n' "${label}"
    return 0
  else
    rc=$?
  fi
  printf '❌ %s\n' "${label}" >&2
  tail -n "${LOG_TAIL}" "${log}" >&2 || true
  rm -f "${log}"
  return "${rc}"
}

if [[ "${BASE_REF}" != "HEAD" ]] && git rev-parse --verify "${BASE_REF}^{commit}" >/dev/null 2>&1; then
  run_compact "Git whitespace/conflict markers against ${BASE_REF}" git diff --check "${BASE_REF}...HEAD"
fi
run_compact "working-tree whitespace/conflict markers" git diff --check
run_compact "staged whitespace/conflict markers" git diff --cached --check

command -v python3 >/dev/null 2>&1 || {
  echo "❌ python3 is required for deterministic workflow/JSON validation" >&2
  exit 1
}

run_compact "release version consistency" python3 scripts/check-version-consistency.py

run_compact "GitHub Actions immutable SHA pins" python3 - <<'PY'
from pathlib import Path
import re
import sys

failures = []
pattern = re.compile(r"^\s*uses:\s*([^\s#]+)")
sha = re.compile(r"^[0-9a-f]{40}$")
for workflow in sorted(Path(".github/workflows").glob("*.y*ml")):
    for lineno, line in enumerate(workflow.read_text(encoding="utf-8").splitlines(), 1):
        match = pattern.match(line)
        if not match:
            continue
        value = match.group(1)
        if value.startswith("./") or value.startswith("docker://"):
            continue
        if "@" not in value:
            failures.append(f"{workflow}:{lineno}: missing @ref: {value}")
            continue
        ref = value.rsplit("@", 1)[1]
        if not sha.fullmatch(ref):
            failures.append(f"{workflow}:{lineno}: action is not pinned to a 40-char SHA: {value}")

if failures:
    print("\n".join(failures), file=sys.stderr)
    sys.exit(1)
PY

shell_files=()
json_files=()
python_files=()
for file in "${CHANGED_FILES[@]}"; do
  case "${file}" in
  *.sh)
    shell_files+=("${file}")
    ;;
  *.json)
    json_files+=("${file}")
    ;;
  *.py)
    python_files+=("${file}")
    ;;
  esac
done

for file in "${shell_files[@]}"; do
  run_compact "bash syntax · ${file}" bash -n "${file}"
done
for file in "${json_files[@]}"; do
  run_compact "JSON syntax · ${file}" python3 -m json.tool "${file}"
done
for file in "${python_files[@]}"; do
  run_compact "Python syntax · ${file}" python3 -m py_compile "${file}"
done

if [[ "${MODE}" == "preflight" ]]; then
  echo "✅ dependency-free quality preflight passed"
  exit 0
fi

command -v pre-commit >/dev/null 2>&1 || {
  echo "❌ pre-commit is required; run 'bash scripts/install-hooks.sh' after installing pre-commit" >&2
  exit 1
}

if ((${#CHANGED_FILES[@]} == 0)); then
  echo "✅ no changed files require pre-commit validation"
  exit 0
fi

before="$(worktree_fingerprint)"
log="$(mktemp)"
set +e
pre-commit run --hook-stage pre-commit --files "${CHANGED_FILES[@]}" --show-diff-on-failure >"${log}" 2>&1
rc=$?
set -e
after="$(worktree_fingerprint)"

if [[ "${before}" != "${after}" ]]; then
  echo "❌ QG_AUTOFIX_REQUIRED: deterministic hooks modified files." >&2
  echo "   Run 'bash scripts/agent-quality-gate.sh --fix', review the diff, commit it, then rerun --publish." >&2
  git status --short >&2
  rm -f "${log}"
  exit 3
fi

if ((rc != 0)); then
  echo "❌ canonical pre-commit validation failed without an automatic rewrite" >&2
  tail -n "${LOG_TAIL}" "${log}" >&2 || true
  rm -f "${log}"
  exit "${rc}"
fi
rm -f "${log}"

echo "✅ canonical formatter/linter gate passed (${MODE})"
