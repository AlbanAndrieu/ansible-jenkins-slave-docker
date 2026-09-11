# GitHub repository rulesets

`main.json` is an importable baseline ruleset for the repository default branch.

The file is intentionally stored with `"enforcement": "disabled"`. Importing policy-as-code must not accidentally lock the default branch before the required checks and any release identity are validated.

## Import

1. Open **Settings → Rules → Rulesets**.
2. Select **New ruleset → Import a ruleset**.
3. Import `.github/rulesets/main.json`.
4. Keep the imported ruleset **Disabled** while validating the repository-specific checks and release workflow.
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

Required checks for this repository are currently:

- `Build Docker`
- `Mega Linter`
- `Analyze Python`

Before activation, confirm that these are still the exact check-run names emitted by GitHub Actions. Rename the entries if a workflow/job name changes.

## FOSSA is advisory

The following FOSSA commit statuses are intentionally **not** included in `required_status_checks`:

- `License Compliance`
- `Security Analysis`
- `Dependency Quality`

They may remain red and visible on a pull request without blocking merge. Do not convert their failures to success merely to satisfy branch protection; the intended policy is **visible but non-blocking**.

## Semantic-release bypass is intentional, but narrow

A release workflow may legitimately need to push a release commit, tag, or release metadata after a protected pull request has merged. In that case a bypass has a real operational purpose.

Do **not** solve this by allowing administrators, all writers, or the generic GitHub Actions identity to bypass the ruleset. Use a dedicated release GitHub App and grant only the permissions required by the release workflow.

For repositories that use semantic-release and push back to the protected default branch:

1. create or reuse a dedicated release GitHub App;
2. install it only on repositories that require release-time write access;
3. grant the minimum repository permissions required by the release workflow;
4. add that App to the live ruleset bypass list with **Always allow**;
5. record the App identity in the central policy-as-code inventory so the bypass is reproducible and reviewable.

`main.json` deliberately keeps `bypass_actors` empty because GitHub App actor IDs and installation availability are repository/account specific. The central IaC layer should inject the dedicated release App only for repositories whose release design requires it.

This repository does not currently contain a semantic-release workflow, so there is no reason to add a release bypass yet.

## Activation checklist

Before changing the live ruleset to **Active**:

- all workflow `uses:` references are pinned to full commit SHAs;
- `Build Docker` is green;
- `Mega Linter` is green;
- `Analyze Python` is green;
- FOSSA statuses are absent from required checks;
- **Do not allow bypassing the above settings** remains enabled for the classic protection while it is still in use;
- if the repository uses semantic-release, its dedicated release App is the only intentional bypass identity;
- the administrator has confirmed that no release/publish workflow depends on an undeclared direct push to the default branch.

## Migration from classic branch protection

Keep the existing classic branch protection active while this ruleset is tested. Once the imported ruleset is active and verified, remove or simplify the classic rule so two independent policies do not drift.

The long-term source of truth is the central GitHub governance IaC described in `docs/ci-hardening-roadmap.md`.
