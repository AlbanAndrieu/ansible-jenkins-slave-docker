# CI hardening roadmap

This repository is the pilot for a reusable GitHub CI/repository-hardening baseline that can later be applied across AlbanAndrieu repositories as infrastructure as code.

The behavioral target is deliberately close to `fastapi-sample` and the agent-first flow used by `nabla-site-bababou`: deterministic fixes happen locally, iterative PRs stay draft, draft CI is cheap, and expensive authoritative gates run only when the branch is ready.

## Design principles

- least privilege for `GITHUB_TOKEN` and external credentials;
- deterministic formatter/linter fixes happen locally before publication whenever possible;
- agents inspect compact local failures before remote CI logs;
- iterative agent PRs stay draft until their publication checkpoint is ready;
- draft CI runs dependency-free preflight only;
- expensive CI starts on `ready_for_review`, not during every editing push;
- third-party Actions are pinned to immutable full commit SHAs;
- required checks are explicit and tied to the expected GitHub integration;
- security/compliance tools may stay visible without being merge-blocking when that is the declared policy;
- bypass authority is exceptional and tied to a dedicated machine identity, never broad administrator bypass;
- release automation is separated from PR validation;
- policy is versioned and eventually reconciled centrally to prevent configuration drift.

## P0 — supply-chain baseline

- [x] Pin every current GitHub Action reference to a full-length commit SHA.
- [x] Keep human-readable version comments beside pinned SHAs.
- [x] Make the legacy `Git Version` workflow explicitly read-only and disable persisted checkout credentials.
- [x] Add an importable default-branch ruleset under `.github/rulesets/`.
- [x] Keep the versioned ruleset disabled by default to prevent accidental lock-out.
- [x] Keep FOSSA License Compliance, Security Analysis, and Dependency Quality advisory/non-required.
- [x] Document the legitimate semantic-release bypass use case and restrict it to a dedicated release GitHub App.
- [ ] After this PR is green and merged, enable **Require actions to be pinned to a full-length commit SHA** in repository Actions settings.

## P1 — local-first quality gate

Implemented in PR #273:

- [x] Add canonical `scripts/quality-gate.sh` with dependency-free preflight and compact formatter/linter validation.
- [x] Add `scripts/agent-quality-gate.sh` with `--fix`, `--preflight` and `--publish` modes.
- [x] Converge deterministic pre-commit rewrites locally with bounded multi-pass retry.
- [x] Detect formatter/linter rewrites as `QG_AUTOFIX_REQUIRED` instead of spending tokens analyzing known-fixable remote logs.
- [x] Guard branch freshness, suspicious large deletions and executable-script mode before expensive validation.
- [x] Require a clean committed tree for strict publication.
- [x] Record an exact local publication proof keyed to HEAD/base/toolchain so pre-push can reuse it.
- [x] Add a dedicated pre-push hook and `scripts/install-hooks.sh`.
- [x] Add `AGENTS.md` with the mandatory local `--fix` -> review/commit -> `--publish` contract.
- [x] Reuse the existing pre-commit configuration as formatter/linter authority rather than creating another toolchain.
- [ ] Burn in the local gate on several real changes and tune only demonstrated false positives/costs.
- [ ] Once proven reliable, make MegaLinter validation read-only.
- [ ] Remove `PAT || GITHUB_TOKEN` write use from PR MegaLinter after the local auto-fix replacement is proven.
- [ ] Remove CI-side auto-commit/create-PR actions when they are no longer needed.

## P1 — draft-first, low-cost remote CI

- [x] Create `Agent Quality / Agent preflight`, dependency-free and capped at five minutes.
- [x] Keep iterative agent PRs draft while editing or until the local publication checkpoint is ready.
- [x] On draft PRs, defer Docker CI, MegaLinter and CodeQL.
- [x] Add `ready_for_review` triggers so authoritative remote gates start when a PR becomes Ready.
- [x] Document the API-only exception: after a successful draft preflight, an atomic PR may be marked Ready to obtain authoritative CI while explicitly disclosing that no local gate ran.
- [ ] Add change-scope classification so required checks always report while expensive implementation steps skip irrelevant changes.
- [ ] In particular, reconcile the path-filtered Docker workflow before making `Build Docker` a live globally-required ruleset check.
- [ ] Measure draft-preflight vs ready-PR Actions duration over several PRs and record the savings.

## P1 — workflow least privilege

- [ ] Set repository default workflow permissions to read-only in **Settings -> Actions -> General**.
- [ ] Disable **Allow GitHub Actions to create and approve pull requests** unless a reviewed automation explicitly requires it.
- [x] Keep `Agent Quality` read-only with checkout credentials disabled.
- [x] Keep Docker/CodeQL validation permissions explicit.
- [x] Make MegaLinter's temporary `contents: write` requirement explicit while auto-fix remains enabled.
- [ ] Remove MegaLinter write permission after the local gate burn-in.
- [ ] Keep checkout `persist-credentials: false` in every read-only job.
- [ ] Separate Docker validation from Docker publication so PR CI never contains registry publication behavior.
- [ ] Move DockerHub write access into a release/publish-only workflow.
- [ ] Review fork PR approval policy and never expose repository secrets to untrusted fork code.
- [ ] Avoid `pull_request_target` unless a narrowly reviewed use case requires it.

## P1 — action allow-list

After SHA pinning is enforced and CI is green:

- [ ] Replace `Allow all actions and reusable workflows` with an allow-list policy.
- [ ] Start with only the owners actually used by this repository (`actions`, `github`, `docker`, `aquasecurity`, `oxsecurity`, and retained reviewed owners).
- [ ] Remove obsolete third-party actions instead of permanently expanding the allow-list.
- [ ] Let Dependabot continue maintaining pinned GitHub Action SHAs.

## P2 — semantic-release parity with fastapi-sample

The target is not merely “have semantic-release”; it is to reproduce the useful security and efficiency properties of `fastapi-sample` while adapting the versioned artifact set to this Docker-image repository.

- [ ] Define the authoritative version contract first (currently `package.json`/Makefile/image metadata contain version information that must not drift).
- [ ] Add a Conventional Commit semantic-release configuration and only the plugins actually required for this repository.
- [ ] Add `.github/workflows/semantic-release.yml` triggered by `push` to `master` plus manual dispatch.
- [ ] Use full-history checkout with `persist-credentials: false`.
- [ ] Add `RELEASE_APP_CLIENT_ID` as an Actions variable and `RELEASE_APP_PRIVATE_KEY` as an Actions secret.
- [ ] Mint a short-lived dedicated GitHub App token with `actions/create-github-app-token`, pinned by full SHA.
- [ ] Grant release-time permissions narrowly (`contents: write` and only issue/PR permissions actually consumed by semantic-release plugins).
- [ ] Make the dedicated release GitHub App the only ruleset bypass identity needed for release commits/tags.
- [ ] Generate synchronized version/changelog changes, release commit where required, immutable tag and GitHub Release.
- [ ] Verify the release baseline/tag before publication and make retries idempotent.
- [ ] Avoid release recursion with an explicit release-commit convention such as `[skip ci]` where appropriate.
- [ ] Split Docker publication out of PR validation; consume the semantic-release tag/version from a release-only workflow or repository dispatch.
- [ ] Build/publish a released Docker image once, rather than rebuilding the same artifact in multiple release jobs.
- [ ] Keep PR validation secret-free; registry credentials exist only on release/publish events.
- [ ] Update `.github/rulesets/README.md` and central IaC inventory when the release App is installed, then inject its actor ID into the live ruleset rather than hard-coding a non-portable ID in the template.

## P2 — ruleset activation

- [ ] Import `.github/rulesets/main.json` as a disabled ruleset.
- [ ] Confirm exact required check names on a fresh Ready PR.
- [ ] Confirm `Agent preflight` always reports.
- [ ] Reconcile path-scoped required checks so they cannot remain permanently Expected/Pending for unrelated changes.
- [ ] Confirm FOSSA statuses remain visible but non-blocking.
- [ ] Keep required checks scoped to the GitHub Actions integration.
- [ ] Verify squash-only merge and linear-history behavior.
- [ ] Verify force-push and branch deletion are blocked.
- [ ] Verify there is no broad administrator bypass.
- [ ] Configure only the dedicated semantic-release GitHub App as bypass actor after the release workflow exists.
- [ ] Activate the ruleset.
- [ ] Retire or simplify the overlapping classic branch-protection rule after successful validation.

## P2 — required-check policy

Proposed required checks after reporting semantics are proven:

- `Agent preflight`
- `Build Docker`
- `Mega Linter` (until local-first burn-in permits a smaller/read-only replacement)
- `Analyze Python`

Advisory only:

- FOSSA `License Compliance`
- FOSSA `Security Analysis`
- FOSSA `Dependency Quality`

Future required checks should be added only when they are deterministic enough that a red status represents an actionable merge blocker rather than third-party noise or accumulated technical debt.

## P3 — central policy as code

The repository-local files are a pilot and documentation source, not the desired final control plane.

Target architecture:

1. Create a central GitHub-governance repository containing reusable policy definitions, reusable workflow/gate templates, and per-repository inventory.
2. Represent repository classes/profiles such as `library`, `site`, `service`, `docker-image`, and `infrastructure`.
3. Define defaults centrally: branch/ruleset policy, draft-first agent policy, Actions permissions, SHA-pinning requirement, action allow-list, Dependabot policy, security settings, and release identity.
4. Keep repository-specific exceptions explicit and reviewable, including advisory FOSSA and whether semantic-release requires a dedicated App bypass.
5. Reconcile repository settings through Terraform/OpenTofu with the GitHub provider, or an equivalently declarative GitHub App/tooling layer where provider coverage is insufficient.
6. Reuse shared gate logic without blindly assuming identical language/build stacks; keep thin repository-specific wrappers where necessary.
7. Run drift detection in CI and report changes before applying them.
8. Apply changes progressively: plan -> review -> canary repository -> second profile -> wider rollout.
9. Never store App private keys, PATs, registry passwords or other credentials in the policy repository; use Actions secrets/OIDC or an external secret manager.

Suggested future inventory shape:

```yaml
repositories:
  ansible-jenkins-slave-docker:
    profile: docker-image
    default_branch: master
    draft_first_agent_prs: true
    require_sha_pinned_actions: true
    fossa_required: false
    semantic_release: true
    release_bypass: dedicated-github-app

  fastapi-sample:
    profile: service
    default_branch: master
    draft_first_agent_prs: true
    require_sha_pinned_actions: true
    fossa_required: false
    semantic_release: true
    release_bypass: dedicated-github-app
```

The exact schema should be finalized only after this pilot and at least one second repository have converged, so the shared model captures real differences rather than assumptions.

## P4 — broader supply-chain hardening

- [ ] Review whether every remaining third-party Action is still necessary.
- [ ] Prefer OIDC/short-lived credentials over long-lived repository secrets where supported.
- [ ] Add artifact provenance/attestation for released Docker images.
- [ ] Review Dependabot configuration and remove template-only/obsolete entries.
- [ ] Add periodic governance drift checks across repositories.
- [ ] Document emergency break-glass procedure separately from normal bypass permissions.
