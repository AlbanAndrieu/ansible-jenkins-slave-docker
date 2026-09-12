# CI hardening roadmap

This repository is the pilot for a reusable GitHub CI/repository-hardening baseline that can later be applied across AlbanAndrieu repositories as infrastructure as code.

Behavioral targets are deliberately aligned with `fastapi-sample` and the agent-first flow used by `nabla-site-bababou`: deterministic fixes happen locally, iterative PRs stay draft, draft CI is cheap, and expensive authoritative gates run only when the branch is ready.

## Design principles

- least privilege for `GITHUB_TOKEN` and external credentials;
- deterministic formatter/linter fixes happen locally before publication;
- agents consume compact local failures before remote CI logs;
- iterative agent PRs stay draft until the publication checkpoint is ready;
- draft CI runs dependency-free preflight only;
- expensive CI starts on `ready_for_review`, not during every editing push;
- third-party Actions are pinned to immutable full commit SHAs;
- required checks are explicit and tied to the expected GitHub integration;
- security/compliance tools may stay visible without being merge-blocking when policy says advisory;
- bypass authority belongs to a dedicated machine identity, never broad administrator bypass;
- release automation is separated from PR validation;
- repository settings and exceptions eventually converge under central policy as code.

## P0 — supply-chain baseline

- [x] Pin current GitHub Action references to full-length commit SHAs.
- [x] Keep readable version comments beside pinned SHAs.
- [x] Harden the legacy Git Version workflow with read-only contents and non-persisted checkout credentials.
- [x] Add an importable default-branch ruleset under `.github/rulesets/`.
- [x] Keep the versioned ruleset disabled by default to prevent accidental lock-out.
- [x] Keep FOSSA License Compliance, Security Analysis and Dependency Quality advisory/non-required.
- [x] Document semantic-release bypass as a dedicated release GitHub App exception.
- [ ] After this PR is green and merged, enable **Require actions to be pinned to a full-length commit SHA** in repository settings.

## P1 — local-first quality gate

- [x] Add canonical `scripts/quality-gate.sh` with dependency-free preflight and compact formatter/linter validation.
- [x] Add `scripts/agent-quality-gate.sh` with `--fix`, `--preflight` and `--publish` modes.
- [x] Converge deterministic pre-commit rewrites locally with bounded multi-pass retry.
- [x] Emit `QG_AUTOFIX_REQUIRED` when strict validation discovers files that should have been fixed locally.
- [x] Guard branch freshness, suspicious large deletions and executable-script modes before expensive validation.
- [x] Require a clean committed tree for strict publication.
- [x] Record an exact publication proof keyed to HEAD/base/toolchain for pre-push reuse.
- [x] Add `.pre-commit-pre-push.yaml` plus `scripts/install-hooks.sh`.
- [x] Version the mandatory agent contract in `AGENTS.md`.
- [x] Reuse existing pre-commit hooks as formatter/linter authority rather than duplicating toolchains.
- [x] Observe a real remote MegaLinter auto-fix on PR #273 and confirm it only applied deterministic shell formatting the local gate is designed to perform.
- [x] Make MegaLinter read-only after that proof.
- [x] Remove MegaLinter `PAT || GITHUB_TOKEN` checkout write path.
- [x] Remove MegaLinter CI-side auto-commit/create-PR actions.
- [ ] Burn in the local gate on several real developer/agent changes and tune only demonstrated false positives/costs.

## P1 — draft-first, low-cost remote CI

- [x] Create `Agent Quality / Agent preflight`, dependency-free and capped at five minutes.
- [x] Keep iterative agent PRs draft while editing or until the local publication checkpoint is ready.
- [x] On draft PRs, defer Docker CI, MegaLinter and CodeQL.
- [x] Add `ready_for_review` triggers so authoritative remote gates start only when a PR becomes Ready.
- [x] Document the API-only exception: after successful draft preflight, an atomic PR may be marked Ready to obtain authoritative CI while disclosing that no local gate ran.
- [x] Validate this lifecycle on PR #273: draft preflight green, heavy jobs skipped; Ready preflight/CodeQL/MegaLinter then started as designed.
- [x] Return PR #273 to draft when the legacy MegaLinter auto-fix rewrote the branch, proving remote CI must not be an editing loop.
- [ ] Add change-scope classification so required checks always report while expensive implementation steps skip irrelevant changes.
- [ ] Reconcile path-filtered Docker workflow before making `Build Docker` a globally required live ruleset check.
- [ ] Record draft-preflight vs Ready-PR Actions duration across several PRs to quantify savings.

## P1 — workflow least privilege

- [x] Keep `Agent Quality` read-only with checkout credentials disabled.
- [x] Keep Docker/CodeQL validation permissions explicit.
- [x] Convert MegaLinter to `contents: read`, disable persisted credentials and remove its write/autofix path.
- [ ] Set repository default workflow permissions to read-only in **Settings -> Actions -> General**.
- [ ] Disable **Allow GitHub Actions to create and approve pull requests** unless a reviewed automation explicitly requires it.
- [ ] Audit every checkout for `persist-credentials: false` where writes are unnecessary.
- [ ] Separate Docker validation from Docker publication so PR CI contains no registry-publish behavior.
- [ ] Move DockerHub write access into a release/publish-only workflow.
- [ ] Review fork PR approval policy and never expose repository secrets to untrusted fork code.
- [ ] Avoid `pull_request_target` unless a narrowly reviewed use case requires it.

## P1 — action allow-list

After SHA pinning is enforced and CI is green:

- [ ] Replace `Allow all actions and reusable workflows` with an allow-list policy.
- [ ] Start with owners actually used by this repository (`actions`, `github`, `docker`, `aquasecurity`, `oxsecurity`, plus any retained reviewed owners).
- [ ] Remove obsolete third-party actions instead of permanently expanding the allow-list.
- [ ] Let Dependabot maintain pinned GitHub Action SHAs.

## P2 — semantic-release parity with fastapi-sample

The target is not merely to install semantic-release. Reproduce the useful security and efficiency properties of `fastapi-sample` while adapting the artifact/version contract to this Docker-image repository.

Current version surfaces already identified:

- `package.json`: `version`, `branchVersion`, `branchPattern`;
- `scripts/docker-build-24.sh`: default Docker tag;
- `Makefile`: default next/release image tag;
- `docker/ubuntu24/Dockerfile`: OCI/image version label;
- `CHANGELOG.md`: released and pending versions.

Roadmap:

- [ ] Decide the authoritative version source and define which other files are generated/synchronized release surfaces.
- [ ] Add a version-consistency checker before any automated release mutation.
- [ ] Reconcile the existing pending `CHANGELOG.md` version with the chosen semantic-release baseline.
- [ ] Add a Conventional Commit semantic-release configuration and only the plugins this repository needs.
- [ ] Add `.github/workflows/semantic-release.yml` on `push` to `master` plus `workflow_dispatch`.
- [ ] Use full-history checkout with `persist-credentials: false`.
- [ ] Add `RELEASE_APP_CLIENT_ID` as an Actions variable and `RELEASE_APP_PRIVATE_KEY` as an Actions secret.
- [ ] Mint a short-lived release token with SHA-pinned `actions/create-github-app-token`.
- [ ] Grant release-time permissions narrowly (`contents: write` plus only issue/PR permissions consumed by configured plugins).
- [ ] Make the dedicated release GitHub App the only ruleset bypass identity needed for release commits/tags.
- [ ] Generate synchronized version/changelog changes, release commit when required, immutable tag and GitHub Release.
- [ ] Validate release baseline/tag before publication and make retries idempotent.
- [ ] Avoid release recursion with an explicit release-commit convention such as `[skip ci]` where appropriate.
- [ ] Split Docker publication from PR validation and consume the semantic-release tag/version from a release-only workflow or repository dispatch.
- [ ] Build/publish the released Docker image once rather than rebuilding identical artifacts in multiple release jobs.
- [ ] Keep PR validation secret-free; registry credentials exist only on release/publish events.
- [ ] Update ruleset documentation and central IaC inventory when the release App is installed; inject its actor ID into the live ruleset instead of hard-coding a non-portable ID in the repository template.

## P2 — ruleset activation

- [ ] Import `.github/rulesets/main.json` as a disabled ruleset.
- [ ] Confirm exact required check names on a fresh Ready PR.
- [ ] Confirm `Agent preflight` always reports.
- [ ] Reconcile path-scoped required checks so they cannot remain permanently Expected/Pending for unrelated changes.
- [ ] Confirm FOSSA statuses remain visible but non-blocking.
- [ ] Keep required checks scoped to GitHub Actions integration ID `15368`.
- [ ] Verify squash-only merge and linear-history behavior.
- [ ] Verify force-push and branch deletion are blocked.
- [ ] Verify there is no broad administrator bypass.
- [ ] Configure only the dedicated semantic-release GitHub App as bypass actor after release workflow/configuration exist.
- [ ] Activate the ruleset.
- [ ] Retire or simplify overlapping classic branch protection after successful validation.

Proposed required checks after reporting semantics are proven:

- `Agent preflight`
- `Build Docker`
- `Mega Linter`
- `Analyze Python`

Advisory only:

- FOSSA `License Compliance`
- FOSSA `Security Analysis`
- FOSSA `Dependency Quality`

## P3 — central policy as code

Repository-local files are the pilot/documentation surface, not the desired final control plane.

Target architecture:

1. Create a central GitHub-governance repository containing reusable policy definitions, workflow/gate templates and per-repository inventory.
2. Model repository profiles such as `library`, `site`, `service`, `docker-image` and `infrastructure`.
3. Define defaults centrally: rulesets, draft-first agent policy, workflow permissions, SHA-pinning, action allow-list, Dependabot policy, security settings and release identity.
4. Keep exceptions explicit and reviewable, including advisory FOSSA and dedicated semantic-release App bypass.
5. Reconcile settings through Terraform/OpenTofu with the GitHub provider, or an equivalent declarative GitHub App/tool where provider coverage is insufficient.
6. Share gate logic without assuming identical language/build stacks; keep thin repository-specific wrappers where necessary.
7. Run drift detection in CI and review plans before applying them.
8. Roll out progressively: plan -> canary repository -> second repository profile -> wider adoption.
9. Never store App private keys, PATs, registry passwords or other credentials in the policy repository.

Suggested inventory direction:

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

Finalize the schema only after this pilot and at least one second repository converge, so shared policy captures real differences rather than assumptions.

## P4 — broader supply-chain hardening

- [ ] Review whether every remaining third-party Action is necessary.
- [ ] Prefer OIDC/short-lived credentials over long-lived secrets where supported.
- [ ] Add provenance/attestation for released Docker images.
- [ ] Review Dependabot configuration and remove template-only/obsolete entries.
- [ ] Add periodic governance drift checks across repositories.
- [ ] Document emergency break-glass separately from normal bypass permissions.
