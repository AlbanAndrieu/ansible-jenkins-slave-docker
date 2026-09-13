# Repository agent policy

Keep context small, changes scoped, and publication deterministic.

## Bootstrap

On a new checkout, install the repository hooks once:

```bash
bash scripts/install-hooks.sh
```

The normal pre-commit hooks are authoritative for deterministic formatting/linting. The separate pre-push hook runs the publication gate and reuses an exact local proof when the committed state has already passed.

## Local-first publication contract

After editing:

```bash
bash scripts/agent-quality-gate.sh --fix
# review every deterministic rewrite
# commit the reviewed change set
bash scripts/agent-quality-gate.sh --publish
```

`--fix` repeatedly runs changed-file pre-commit hooks until deterministic rewrites converge or no further progress is possible. If a formatter or linter changes files, review and commit those changes before publication. Do not spend remote CI minutes or agent tokens diagnosing formatter churn that can be resolved locally.

`--publish` requires a clean committed tree, runs the canonical gate, and records an exact proof keyed to HEAD, comparison base and toolchain. The pre-push hook reuses that proof when it remains valid.

Never use `git push --no-verify` and never weaken validation merely to make a push pass.

## Draft pull-request contract

Keep iterative agent pull requests in **draft** while changes are still being edited or while the local publication checkpoint is not proven green.

Draft PR CI runs only the dependency-free `Agent preflight`. Docker image builds, MegaLinter and CodeQL wait until the PR becomes Ready for review.

Once `bash scripts/agent-quality-gate.sh --publish` is green, mark the PR **Ready for review**. The `ready_for_review` event then starts authoritative remote gates.

An API-only agent that cannot execute a real checkout must not claim the local gate passed. It should keep the PR draft while iterating, publish atomic changes when possible, inspect the draft preflight, and only then mark the PR Ready when authoritative CI is required while explicitly disclosing that no workstation-local publication gate ran.

If an authoritative remote gate rewrites the branch, return the PR to draft before continuing. Remote CI must not be used as an editing loop.

## CI permissions and MegaLinter

MegaLinter is **read-only**. It must not receive a PAT, persisted checkout credentials, or `contents: write`, and it must not auto-commit fixes or create fix PRs. Deterministic fixes belong in `agent-quality-gate.sh --fix` before push.

Read-only validation jobs should use `permissions: contents: read` plus only narrowly required extra permissions. Release/publish write permissions belong in dedicated workflows, never ordinary PR validation.

## Docker contract

Canonical Ubuntu 24 image work remains on:

- `scripts/docker-build-24.sh`
- `docker/ubuntu24/Dockerfile`
- `docker/ubuntu24/config.yaml`

`Build Docker` must always report on a Ready PR so it can safely become a required check. A cheap Git/Bash scope classifier may skip Python/Node setup, image build, CST and Trivy for unrelated changes, but the check itself must still complete successfully with an explicit no-op summary.

PR validation must build/test/scan when Docker-relevant paths change, but it must never push DockerHub images or receive registry credentials. DockerHub credentials are limited to non-PR publication steps until publication moves into its dedicated semantic-release-driven workflow.

## Version contract

`package.json` `version` is the current-release source of truth until semantic-release owns version mutation. The dependency-free preflight runs `scripts/check-version-consistency.py`, which requires these release surfaces to agree with it:

- `package.json` `branchVersion` and `branchPattern`;
- `scripts/docker-build-24.sh` default `DOCKER_TAG`;
- `Makefile` default `DOCKER_NEXT_TAG`;
- `docker/ubuntu24/Dockerfile` version label;
- the released-version section in `CHANGELOG.md`.

Historical `CHANGELOG.md` `TODO` sections older than the current release are legacy documentation debt, not release intent. At most one future `TODO` version may be treated as the pending semantic-release baseline while migration is in progress.

## Semantic-release target

Converge toward the `fastapi-sample` release model:

- Conventional Commit driven semantic-release on `master`;
- full-history checkout with persisted credentials disabled;
- short-lived token from a dedicated release GitHub App;
- only that App may bypass the protected-branch ruleset when release commits/tags must be pushed;
- synchronized version/changelog/tag/GitHub Release;
- release-tag-driven Docker publication separated from PR CI;
- no broad administrator or generic GitHub Actions bypass.

Before implementing semantic-release mutations, keep the version contract green and reconcile the pending changelog baseline deliberately.

## Efficiency

Inspect CI progressively: workflow status -> failing job -> failing step -> relevant log tail/artifact -> full logs only when necessary. Prefer local compact failures over remote logs and avoid repeated polling or unnecessary commits that restart expensive workflows.

## Completion

Report what changed, what was actually executed, whether the PR is draft or ready, and any unresolved failure or risk. Never merge a PR without an explicit user request.
