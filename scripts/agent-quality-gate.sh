#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "${ROOT}"

MODE="check"
case "${1:-}" in
--fix)
  MODE="fix"
  shift
  ;;
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
  bash scripts/agent-quality-gate.sh [--fix|--preflight|--publish]

Modes:
  default      strict agent validation on a committed branch
  --fix        converge deterministic pre-commit rewrites on changed files
  --preflight  dependency-free Git/structure gate used by draft PR CI
  --publish    strict local publication gate with exact-state proof reuse

Environment:
  QUALITY_BASE_REF                 override comparison base
  QUALITY_LOG_TAIL                 failure log lines to print (default: 50)
  QUALITY_FIX_MAX_PASSES           max deterministic fix passes (default: 5)
  QUALITY_ALLOW_LARGE_DELETION=1   acknowledge an intentional large truncation/deletion
  QUALITY_FORCE_PUBLISH=1          ignore the exact-state publication proof
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
FIX_MAX_PASSES="${QUALITY_FIX_MAX_PASSES:-5}"
STAMP_PATH="$(git rev-parse --git-path nabla-agent-quality.stamp)"

if ! [[ "${FIX_MAX_PASSES}" =~ ^[1-9][0-9]*$ ]]; then
  printf '❌ QUALITY_FIX_MAX_PASSES must be a positive integer\n' >&2
  exit 2
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

if [[ "${BASE_REF}" != "HEAD" ]]; then
  if ! git rev-parse --verify "${BASE_REF}^{commit}" >/dev/null 2>&1; then
    printf '❌ QG_BASE_MISSING: comparison base %s is unavailable\n' "${BASE_REF}" >&2
    exit 1
  fi
  if ! git merge-base --is-ancestor "${BASE_REF}" HEAD; then
    printf '❌ QG_BASE_STALE: HEAD does not contain %s; fetch/rebase before publication\n' "${BASE_REF}" >&2
    exit 1
  fi
  printf '✅ branch contains comparison base %s\n' "${BASE_REF}"
fi

collect_changed_files() {
  {
    if [[ "${BASE_REF}" != "HEAD" ]]; then
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

collect_deleted_files() {
  {
    if [[ "${BASE_REF}" != "HEAD" ]]; then
      git diff --name-only --diff-filter=D "${BASE_REF}...HEAD"
    fi
    git diff --name-only --diff-filter=D
    git diff --cached --name-only --diff-filter=D
  } | awk 'NF' | sort -u
}

mapfile -t CHANGED_FILES < <(collect_changed_files)
mapfile -t DELETED_FILES < <(collect_deleted_files)

is_guarded_path() {
  case "$1" in
  Pipfile.lock | package-lock.json | *.lock)
    return 1
    ;;
  *.md | *.py | *.sh | *.js | *.mjs | *.json | *.yml | *.yaml | *.toml | Dockerfile* | Makefile)
    return 0
    ;;
  *)
    return 1
    ;;
  esac
}

large_deletion_failed=0
if [[ "${QUALITY_ALLOW_LARGE_DELETION:-0}" != "1" && "${BASE_REF}" != "HEAD" ]]; then
  for file in "${CHANGED_FILES[@]}"; do
    is_guarded_path "${file}" || continue
    git cat-file -e "${BASE_REF}:${file}" 2>/dev/null || continue
    base_lines="$(git show "${BASE_REF}:${file}" | wc -l | tr -d ' ')"
    current_lines="$(wc -l <"${file}" | tr -d ' ')"
    if ((base_lines < 200 || current_lines >= base_lines)); then
      continue
    fi
    deleted_lines=$((base_lines - current_lines))
    deleted_percent=$((deleted_lines * 100 / base_lines))
    if ((deleted_lines >= 100 && deleted_percent >= 40)); then
      printf '❌ QG_LARGE_DELETION: %s lost %d/%d lines (%d%%); set QUALITY_ALLOW_LARGE_DELETION=1 only after explicit review\n' \
        "${file}" "${deleted_lines}" "${base_lines}" "${deleted_percent}" >&2
      large_deletion_failed=1
    fi
  done

  for file in "${DELETED_FILES[@]}"; do
    is_guarded_path "${file}" || continue
    git cat-file -e "${BASE_REF}:${file}" 2>/dev/null || continue
    base_lines="$(git show "${BASE_REF}:${file}" | wc -l | tr -d ' ')"
    if ((base_lines >= 200)); then
      printf '❌ QG_LARGE_DELETION: %s was deleted (%d lines); set QUALITY_ALLOW_LARGE_DELETION=1 only after explicit review\n' \
        "${file}" "${base_lines}" >&2
      large_deletion_failed=1
    fi
  done
fi
if ((large_deletion_failed != 0)); then
  exit 1
fi
printf '✅ destructive-diff guard\n'

exec_bit_failed=0
for file in "${CHANGED_FILES[@]}"; do
  IFS= read -r first_line <"${file}" || true
  [[ "${first_line:-}" == '#!'* ]] || continue
  if git ls-files --error-unmatch -- "${file}" >/dev/null 2>&1; then
    mode="$(git ls-files --stage -- "${file}" | awk 'NR == 1 {print $1}')"
    if [[ "${mode}" != "100755" ]]; then
      printf '❌ QG_EXEC_BIT: %s has a shebang but Git mode is %s; run git add --chmod=+x %q\n' \
        "${file}" "${mode:-unknown}" "${file}" >&2
      exec_bit_failed=1
    fi
  elif [[ ! -x "${file}" ]]; then
    printf '❌ QG_EXEC_BIT: untracked %s has a shebang but is not executable\n' "${file}" >&2
    exec_bit_failed=1
  fi
done
if ((exec_bit_failed != 0)); then
  exit 1
fi
printf '✅ executable-script contract\n'

if [[ "${MODE}" == "preflight" ]]; then
  QUALITY_BASE_REF="${BASE_REF}" bash scripts/quality-gate.sh --preflight
  echo "✅ Agent preflight passed without installing project dependencies."
  exit 0
fi

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

converge_precommit_fixes() {
  command -v pre-commit >/dev/null 2>&1 || {
    echo "❌ pre-commit is required; install it and run 'bash scripts/install-hooks.sh'" >&2
    exit 1
  }

  if ((${#CHANGED_FILES[@]} == 0)); then
    echo "✅ no changed files require deterministic fixes"
    return 0
  fi

  local pass before after log rc
  for ((pass = 1; pass <= FIX_MAX_PASSES; pass++)); do
    before="$(worktree_fingerprint)"
    log="$(mktemp)"
    set +e
    pre-commit run --hook-stage pre-commit --files "${CHANGED_FILES[@]}" --show-diff-on-failure >"${log}" 2>&1
    rc=$?
    set -e
    after="$(worktree_fingerprint)"

    if ((rc == 0)); then
      rm -f "${log}"
      printf '✅ deterministic pre-commit fix converged in %d pass(es)\n' "${pass}"
      return 0
    fi

    if [[ "${before}" != "${after}" ]]; then
      printf '🔧 pre-commit pass %d/%d modified files; retrying without remote log analysis\n' \
        "${pass}" "${FIX_MAX_PASSES}"
      rm -f "${log}"
      mapfile -t CHANGED_FILES < <(collect_changed_files)
      continue
    fi

    echo "❌ QG_FIX_NO_PROGRESS: hooks failed without changing the tree." >&2
    tail -n "${LOG_TAIL}" "${log}" >&2 || true
    rm -f "${log}"
    return "${rc}"
  done

  echo "❌ QG_FIX_NOT_CONVERGED: deterministic fixes still change files after ${FIX_MAX_PASSES} passes." >&2
  git status --short >&2
  return 1
}

if [[ "${MODE}" == "fix" ]]; then
  converge_precommit_fixes
  QUALITY_BASE_REF="${BASE_REF}" bash scripts/quality-gate.sh --preflight
  echo "✅ deterministic local fixes converged"
  echo "ℹ️  review git diff/status, commit the fixes, then run 'bash scripts/agent-quality-gate.sh --publish'"
  git status --short
  exit 0
fi

STATUS="$(git status --short)"
if [[ -n "${STATUS}" ]]; then
  echo "❌ QG_DIRTY_TREE: strict agent validation requires committed changes" >&2
  printf '%s\n' "${STATUS}" >&2
  echo "   Run --fix, review deterministic changes, then commit before --publish." >&2
  exit 1
fi

command -v pre-commit >/dev/null 2>&1 || {
  echo "❌ pre-commit is required; install it and run 'bash scripts/install-hooks.sh'" >&2
  exit 1
}

publication_key() {
  local base_sha
  if [[ "${BASE_REF}" == "HEAD" ]]; then
    base_sha="$(git rev-parse HEAD)"
  else
    base_sha="$(git rev-parse "${BASE_REF}^{commit}")"
  fi
  {
    printf 'head=%s\n' "$(git rev-parse HEAD)"
    printf 'base=%s\n' "${base_sha}"
    printf 'precommit=%s\n' "$(pre-commit --version)"
    printf 'python=%s\n' "$(python3 --version 2>&1)"
  } | git hash-object --stdin
}

STAMP_KEY="$(publication_key)"
if [[ "${MODE}" == "publish" && "${QUALITY_FORCE_PUBLISH:-0}" != "1" && -f "${STAMP_PATH}" ]]; then
  if [[ "$(cat "${STAMP_PATH}")" == "${STAMP_KEY}" ]]; then
    echo "✅ QG_PUBLISH_CACHE: exact HEAD/base/toolchain already passed the local publication gate."
    exit 0
  fi
fi

if [[ "${MODE}" == "publish" ]]; then
  QUALITY_BASE_REF="${BASE_REF}" bash scripts/quality-gate.sh --publish
else
  QUALITY_BASE_REF="${BASE_REF}" bash scripts/quality-gate.sh
fi

mkdir -p "$(dirname "${STAMP_PATH}")"
printf '%s\n' "${STAMP_KEY}" >"${STAMP_PATH}"

if [[ "${MODE}" == "publish" ]]; then
  echo "✅ Agent publication gate passed; exact local proof recorded for pre-push reuse."
else
  echo "✅ Agent quality gate passed; exact local proof recorded."
fi
