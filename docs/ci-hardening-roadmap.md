# CI hardening roadmap

This repository is the pilot for a reusable GitHub CI/repository-hardening baseline that can later be applied across AlbanAndrieu repositories as infrastructure as code.

## Design principles

- least privilege for `GITHUB_TOKEN` and external credentials;
- deterministic formatter/linter fixes happen locally before publication whenever possible;
- CI validates rather than silently repairing published code;
- third-party Actions are pinned to immutable full commit SHAs;
- required checks are explicit and tied to the expected GitHub integration;
- security/compliance tools may stay visible without being merge-blocking when that is the declared policy;
- bypass authority is exceptional and tied to a dedicated machine identity, never broad administrator bypass;
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

Current state: this repository does **not** yet have the local-first `quality-gate` used by newer repositories. MegaLinter auto-fix therefore still provides useful behavior and is intentionally retained during P0.

Target:

- [ ] Add a deterministic local quality gate, for example `scripts/quality-gate.sh`.
- [ ] Provide a `--fix` mode that applies formatter/linter fixes locally.
- [ ] Re-run the gate after fixes until the workspace is clean.
- [ ] Document the same contract for humans and coding agents: if a formatter/linter modifies files, commit those fixes and rerun the gate before push.
- [ ] Reuse pre-commit where it is authoritative instead of duplicating formatter/linter toolchains.
- [ ] Keep the fast path cheap so expensive Docker/security jobs do not run when deterministic formatting/lint is already known to fail.
- [ ] Once the local gate has proven reliable, make MegaLinter validation read-only.
- [ ] Remove `PAT || GITHUB_TOKEN` write use from PR validation after the local auto-fix replacement is in place.
- [ ] Remove CI-side auto-commit/create-PR actions when they are no longer needed.

## P1 — workflow least privilege

- [ ] Set repository default workflow permissions to read-only.
- [ ] Disable **Allow GitHub Actions to create and approve pull requests** unless a reviewed automation explicitly requires it.
- [ ] Declare explicit `permissions:` for every workflow/job.
- [ ] Keep checkout `persist-credentials: false` in read-only jobs.
- [ ] Separate Docker validation from Docker publication so PR CI never needs publication credentials.
- [ ] Move DockerHub write access into a release/publish-only workflow.
- [ ] Review fork PR approval policy and never expose repository secrets to untrusted fork code.
- [ ] Avoid `pull_request_target` unless a narrowly reviewed use case requires it.

## P1 — action allow-list

After SHA pinning is enforced and CI is green:

- [ ] Replace `Allow all actions and reusable workflows` with an allow-list policy.
- [ ] Start with only the owners actually used by this repository (`actions`, `github`, `docker`, `aquasecurity`, `oxsecurity`, and any retained reviewed action owners).
- [ ] Remove obsolete third-party actions instead of permanently expanding the allow-list.
- [ ] Let Dependabot continue maintaining pinned GitHub Action SHAs.

## P2 — ruleset activation

- [ ] Import `.github/rulesets/main.json` as a disabled ruleset.
- [ ] Confirm exact required check names on a fresh pull request.
- [ ] Confirm FOSSA statuses remain visible but non-blocking.
- [ ] Keep required checks scoped to the GitHub Actions integration.
- [ ] Verify squash-only merge and linear-history behavior.
- [ ] Verify force-push and branch deletion are blocked.
- [ ] Verify there is no broad administrator bypass.
- [ ] If semantic-release is introduced and must push to the protected branch, configure only the dedicated release GitHub App as bypass actor.
- [ ] Activate the ruleset.
- [ ] Retire or simplify the overlapping classic branch-protection rule after successful validation.

## P2 — required-check policy

Initial required checks:

- `Build Docker`
- `Mega Linter`
- `Analyze Python`

Advisory only:

- FOSSA `License Compliance`
- FOSSA `Security Analysis`
- FOSSA `Dependency Quality`

Future required checks should be added only when they are deterministic enough that a red status represents an actionable merge blocker rather than third-party noise or accumulated technical debt.

## P3 — central policy as code

The repository-local files are a pilot and documentation source, not the desired final control plane.

Target architecture:

1. Create a central GitHub-governance repository containing reusable policy definitions and per-repository inventory.
2. Represent repository classes/profiles such as `library`, `site`, `service`, `docker-image`, and `infrastructure`.
3. Define defaults centrally: branch/ruleset policy, Actions permissions, SHA-pinning requirement, action allow-list, Dependabot policy, security settings, and optional release bypass identity.
4. Keep repository-specific exceptions explicit and reviewable, for example `semantic_release_bypass: true` or an advisory FOSSA policy.
5. Reconcile settings through Terraform/OpenTofu with the GitHub provider, or an equivalently declarative GitHub App/tooling layer where provider coverage is insufficient.
6. Run drift detection in CI and report changes before applying them.
7. Apply changes progressively: plan -> review -> canary repository -> wider rollout.
8. Never store App private keys, PATs, or other credentials in the policy repository; use GitHub Actions secrets/OIDC or an external secret manager.

Suggested future inventory shape:

```yaml
repositories:
  ansible-jenkins-slave-docker:
    profile: docker-image
    default_branch: master
    require_sha_pinned_actions: true
    fossa_required: false
    semantic_release_bypass: false

  fastapi-sample:
    profile: service
    require_sha_pinned_actions: true
    fossa_required: false
    semantic_release_bypass: true
```

The exact schema should be finalized only after this pilot and at least one second repository have converged, so the shared model captures real differences rather than assumptions.

## P4 — broader supply-chain hardening

- [ ] Review whether every remaining third-party Action is still necessary.
- [ ] Prefer OIDC/short-lived credentials over long-lived repository secrets where supported.
- [ ] Add artifact provenance/attestation for published images where useful.
- [ ] Review Dependabot configuration and remove template-only/obsolete entries.
- [ ] Add periodic governance drift checks across repositories.
- [ ] Document emergency break-glass procedure separately from normal bypass permissions.
