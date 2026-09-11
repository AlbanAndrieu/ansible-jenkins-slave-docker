# Repository agent policy

Keep context small, changes scoped, and publication deterministic.

## Bootstrap

On a new checkout, install the repository hooks once:

```bash
bash scripts/install-hooks.sh
```

The normal pre-commit hooks remain authoritative for deterministic formatting/linting. The separate pre-push hook runs the agent publication gate and reuses an exact local proof when the committed state has already passed.

## Before editing

1. Inspect `git status --short`, the task, and only the relevant files.
2. Prefer targeted search/diffs over recursive repository reads.
3. Reuse existing pre-commit, Docker validation, CST, Trivy, CodeQL and MegaLinter contracts instead of inventing parallel validation.
4. Keep canonical Ubuntu 24 image work on `scripts/docker-build-24.sh` + `docker/ubuntu24/Dockerfile`.

## Local-first quality workflow

After an editing batch:

```bash
bash scripts/agent-quality-gate.sh --fix
# review deterministic formatter/linter rewrites
# commit the reviewed change set
bash scripts/agent-quality-gate.sh --publish
```

`--fix` repeatedly runs changed-file pre-commit hooks until deterministic rewrites converge or no further progress is possible. Do not analyze remote CI logs for formatter churn that can be fixed locally.

`--publish` requires a clean committed tree, runs the canonical gate, and records an exact proof keyed to the committed HEAD, comparison base and local toolchain. The pre-push hook calls the same command and reuses that proof when it is still valid, avoiding duplicate expensive local work.

Never use `git push --no-verify`. If a formatter/linter changes files, review and commit those changes, then rerun `--publish`.

## Draft pull-request contract

Keep iterative agent pull requests in **draft** while changes are still being edited or while the local publication checkpoint is not proven green.

Draft PR CI is deliberately cheap: it runs only the dependency-free agent preflight. Docker image builds, MegaLinter and CodeQL wait until the PR becomes ready for review.

Once the local `bash scripts/agent-quality-gate.sh --publish` gate is green, mark the PR **Ready for review**. The `ready_for_review` event then starts the authoritative remote gates.

An API-only agent that cannot execute a real checkout must not claim the local gate passed. It should:

1. keep the PR draft while iterating;
2. publish one atomic commit/tree when possible;
3. inspect the draft `Agent preflight` result;
4. after that preflight succeeds, mark the atomic PR ready only when authoritative remote CI is required;
5. disclose that no workstation-local publication gate was executed.

This is the same cost-control contract used by newer Nabla repositories: cheap deterministic failures first, expensive GitHub Actions only after the branch is ready.

## CI inspection efficiency

Inspect CI progressively:

1. workflow/check status;
2. failing job;
3. failing step;
4. relevant log tail or artifact;
5. full logs only when narrower evidence is insufficient.

Avoid repeatedly polling unchanged runs. Prefer a fresh commit only when code/configuration actually changes; use failed-job reruns for infrastructure flakes.

## MegaLinter transition

MegaLinter auto-fix is temporarily retained as a fallback while this local-first gate is being proven. The target state is read-only MegaLinter validation with no PAT/GITHUB_TOKEN write path in PR CI once local `--fix` is reliable.

## Semantic release target

The repository is expected to converge toward the `fastapi-sample` release model:

- Conventional Commit driven semantic-release on `master`;
- full-history checkout with persisted credentials disabled;
- a short-lived token from a dedicated release GitHub App;
- only that release App may bypass the protected-branch ruleset when a release commit/tag must be pushed;
- version/changelog/tag/GitHub Release generation is separated from ordinary PR validation;
- Docker publication should consume the released version/tag rather than giving PR CI registry-write credentials.

Do not grant broad administrator or generic GitHub Actions bypass solely to make release automation work.

## Completion

Report what changed, what was actually executed, whether the PR is still draft or ready, and any unresolved failure or risk. Never merge a PR without an explicit user request.
