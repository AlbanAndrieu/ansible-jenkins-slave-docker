# Nabla runner-build image

This is the focused build-tool profile for current Nabla projects. It is deliberately separate from `docker/ubuntu24/Dockerfile`, which remains a broad legacy Jenkins/Selenium image.

## Baseline

- Ubuntu 24.04 LTS
- mise 2026.9.1
- Python 3.13.x
- uv 0.12.12
- Node.js 25.9.0
- npm 11.17.0
- Docker CLI + Buildx + Compose client
- git, jq, rsync, OpenSSH client and native build essentials

The image does **not** run Docker Engine. It also does not bundle Selenium, Chrome, PHP/Apache, LibreOffice/OCR, Java, Nomad or unrelated application stacks.

## Why these versions

`AlbanAndrieu/fastapi-sample` currently requires Python `3.13.*` and uses `uv` plus repository-owned `mise` quality tasks.

`AlbanAndrieu/nabla-site-alban` currently requires Node `>=24.11.0 <26`, npm `>=11.17.0 <12`, and pins Node `25.9.0` in `.nvmrc`. Its browser tests use Playwright; the matching Chromium build should be installed from the consuming project's lockfile rather than baked into this image.

## Build and validate

```bash
bash scripts/docker-build-runner.sh
```

The smoke verifies Ubuntu, Python, Node, npm, mise, uv and Docker client tooling.

## Project smoke targets

### fastapi-sample

Inside this environment, a clean checkout should be able to run:

```bash
uv sync --locked
mise run agent-fix
mise run agent-publish
```

The project remains the source of truth for Python dependencies and higher-level CLI versions.

### nabla-site-alban

Inside this environment, a clean checkout should be able to run:

```bash
npm ci
npm run quality:agent:fix
npm run quality:agent:publish
npm run build
npx playwright install chromium
npm run test:baselines
```

`npx playwright install --with-deps chromium` can be used when the host image still lacks a browser OS dependency. The `runner` user has passwordless sudo for disposable CI/container use; the future TrueNAS LXC should use a narrower sudo policy after its required packages are installed.

## TrueNAS LXC relationship

This OCI image is a **toolchain contract and disposable build environment**, not an LXC image. The TrueNAS GitHub Actions runner should provision an Ubuntu 24.04 LXC with an equivalent minimal toolset.

For Docker-heavy jobs, do not mount the TrueNAS host Docker socket. TrueNAS 26 requires privileged ID mapping and `Capabilities=ALLOW` for Docker nested inside LXC, so prefer a remote builder from an unprivileged runner. If nested Docker is necessary, isolate it in a separate trusted-only runner or use a VM.
