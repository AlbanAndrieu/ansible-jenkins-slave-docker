# AGENTS.md

## Scope

These instructions apply to the whole repository.

## Canonical build path

- Reuse `scripts/docker-build-24.sh` for the Ubuntu 24 / Jenkins build image.
- Do not add a parallel Dockerfile or a second runner-specific build script unless the repository owner explicitly asks for one.
- The default Dockerfile for the canonical script is `docker/ubuntu24/Dockerfile`; keep it as the source of truth for the current Ubuntu 24 image.
- `scripts/docker-build-24.sh` may bootstrap the `albanandrieu.shell` role because several scripts are symlinks into `roles/albanandrieu.shell/files/`.
- In CI use `RUN_ANSIBLE_SETUP=false`: the full workstation Ansible provisioning is a local/admin operation and is too broad for a Docker image build job.

## CI toolchain

The current CI baseline is:

- Ubuntu 24.04
- Python 3.13.15
- Ansible Core 2.21.4
- Pipenv 2026.8.0
- Node.js 25.9.0
- npm 11.17.0
- Docker Buildx
- Container Structure Test 1.22.1

Keep these values aligned between GitHub Actions, the Docker image and the projects that consume the runner. `fastapi-sample` is the Python 3.13 acceptance workload; `nabla-site-alban` is the Node/npm acceptance workload.

The image contract in `docker/ubuntu24/config.yaml` should validate durable runtime capabilities rather than patch-level details that are intentionally allowed to float. When a Dockerfile toolchain is upgraded, update the contract in the same change.

## Required validation after changes

Run deterministic checks before publishing a branch whenever the local environment supports them:

```bash
bash -n scripts/docker-build-24.sh
bash -n scripts/docker-test.sh
shellcheck scripts/docker-build-24.sh scripts/docker-test.sh

CI=true \
RUN_ANSIBLE_SETUP=false \
DOCKER_TAG=agent-smoke \
DOCKER_BUILD_ARGS='--pull' \
bash scripts/docker-build-24.sh

CST_CONFIG=docker/ubuntu24/config.yaml \
bash scripts/docker-test.sh ansible-jenkins-slave-docker agent-smoke
```

For workflow changes, also verify YAML/lint checks used by MegaLinter. If a formatter or linter changes files, commit those changes and rerun the gate until it is clean.

## GitHub Actions behavior

- Pull requests must build, validate the image contract and scan the image but must not push it to DockerHub.
- DockerHub login/push is allowed only for trusted non-PR runs with configured credentials.
- Do not make PR validation depend on repository secrets.
- Prefer immutable action SHAs where a validated SHA is already known in the repository ecosystem.
- Keep checkout shallow unless history is genuinely required.
- Temporary feature-branch self-test triggers must be removed before merge.

## Secrets and build arguments

- Do not print secrets.
- Do not pass `ANSIBLE_VAULT_PASSWORD`, package tokens or other credentials as Docker build arguments unless the Dockerfile demonstrably needs them; build arguments are not an appropriate secret transport.
- Prefer BuildKit secret mounts when a future build genuinely requires a credential.

## Runner / TrueNAS direction

The planned TrueNAS LXC GitHub Actions runner should reuse this existing image/build contract. Do not mount the TrueNAS host Docker socket into the runner. Prefer an unprivileged runner and a separately controlled Docker/BuildKit endpoint for trusted Docker workloads.

## Pull requests

- Keep changes focused and backward-compatible with the existing Jenkins image unless explicitly asked otherwise.
- Do not merge automatically.
- Explain any skipped local validation honestly; remote CI is not a substitute for a local gate when the local gate is available.
