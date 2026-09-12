# GitHub repository rulesets

`main.json` is an importable baseline ruleset for the repository default branch.

The file is intentionally stored with `"enforcement": "disabled"`. Importing policy-as-code must not accidentally lock the default branch before required checks and the release identity are validated.

## Import

1. Open **Settings → Rules → Rulesets**.
2. Select **New ruleset → Import a ruleset**.
3. Import `.github/rulesets/main.json`.
4. Keep the imported ruleset **Disabled** while validating repository-specific checks and release behavior.
5. Activate it only after the checklist below is complete.

## Baseline protections

The baseline:

- requires changes to the default branch to arrive through a pull request;
- allows only squash merges;
- requires review conversations to be resolved;
- requires a linear history;
- prevents force pushes;
- prevents deletion of the default branch;
- requires the branch to be current with the default branch before merge;
- pins required status checks to the official GitHub Actions integration (`integration_id: 15368`).

Required checks are currently modeled as:

- `Agent preflight` — dependency-free structural/agent contract;
- `Build Docker` — authoritative Ubuntu 24 image build/CST/Trivy path;
- `Mega Linter` — broad lint validation while the local-first gate is being proven;
- `Analyze Python` — CodeQL.

Before activation, confirm these are still the exact check-run names emitted by GitHub Actions. A required check must also be guaranteed to report for every mergeable PR; do not activate the ruleset until path-scoped workflows have been reconciled with that requirement.

## Draft PR contract

Iterative agent PRs stay **draft** while they are being edited or until the local publication gate is proven green.

Draft CI runs only `Agent preflight`. Expensive Docker, MegaLinter and CodeQL jobs are deferred. When the PR becomes **Ready for review**, the `ready_for_review` event starts the authoritative remote gates.

An API-only agent may move an atomic draft PR to Ready after the draft preflight passes when it needs authoritative CI, but it must disclose that no workstation-local `--publish` gate was executed.

## FOSSA is advisory

The following FOSSA commit statuses are intentionally **not** included in `required_status_checks`:

- `License Compliance`
- `Security Analysis`
- `Dependency Quality`

They may remain red and visible without blocking merge. Do not rewrite their failures to success merely to satisfy branch protection; the policy is **visible but non-blocking**.

## Semantic-release bypass is intentional, but narrow

This repository is planned to adopt a semantic-release flow aligned with `fastapi-sample`: Conventional Commits on `master`, a release commit/version update when required, a tag and GitHub Release, and Docker publication driven from the released version/tag rather than from PR CI.

That release workflow may legitimately need to push a release commit/tag to the protected default branch. In that case a bypass has a real operational purpose.

Do **not** solve this by allowing administrators, all writers, or the generic GitHub Actions identity to bypass the ruleset. Use a dedicated release GitHub App and grant only the permissions required by the release workflow.

For repositories using this model:

1. create or reuse a dedicated release GitHub App;
2. install it only on repositories requiring release-time write access;
3. store its client ID as an Actions variable and private key as an Actions secret;
4. mint a short-lived installation token in the release workflow;
5. add only that App to the live ruleset bypass list with **Always allow**;
6. record the App identity and release policy in the central governance IaC inventory.

`main.json` deliberately keeps `bypass_actors` empty because GitHub App actor IDs and installation availability are repository/account specific. The central IaC layer should inject the dedicated release App only after the semantic-release workflow and credentials are configured and validated.

## Activation checklist

Before changing the live ruleset to **Active**:

- all workflow `uses:` references are pinned to full commit SHAs;
- `Agent preflight` is green and reports for every PR;
- `Build Docker` is green and its required-check reporting semantics are safe for non-Docker changes;
- `Mega Linter` is green;
- `Analyze Python` is green;
- FOSSA statuses are absent from required checks;
- **Do not allow bypassing the above settings** remains enabled for the classic protection while it is still in use;
- if semantic-release is active, its dedicated release App is the only intentional ruleset bypass identity;
- no release/publish workflow depends on an undeclared direct push to the default branch.

## Migration from classic branch protection

Keep the existing classic branch protection active while this ruleset is tested. Once the imported ruleset is active and verified, remove or simplify the classic rule so two independent policies do not drift.

The long-term source of truth is the central GitHub governance IaC described in `docs/ci-hardening-roadmap.md`.
