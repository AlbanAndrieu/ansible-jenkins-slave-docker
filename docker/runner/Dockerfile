# syntax=docker/dockerfile:1.7

# Focused build environment for Nabla CI/self-hosted runners.
# The historical docker/ubuntu24 image remains available for legacy Jenkins jobs.
ARG UBUNTU_VERSION=24.04
FROM ubuntu:${UBUNTU_VERSION}

ARG DEBIAN_FRONTEND=noninteractive
ARG MISE_VERSION=2026.9.5
ARG MISE_INSTALLER_SHA256=321a141eefbe15f2c5eae16aeacfb04dee3d7bde5363be33d133fc1badb332ef
ARG PYTHON_VERSION=3.13
ARG NODE_VERSION=25.9.0
ARG NPM_VERSION=11.17.0
ARG UV_VERSION=0.12.12
ARG RUNNER_UID=1001
ARG RUNNER_GID=1001

LABEL org.opencontainers.image.title="nabla-runner-build" \
      org.opencontainers.image.description="Focused Ubuntu build environment for fastapi-sample and nabla-site-alban" \
      org.opencontainers.image.source="https://github.com/AlbanAndrieu/ansible-jenkins-slave-docker"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    MISE_DATA_DIR=/usr/local/share/mise \
    MISE_CONFIG_DIR=/etc/mise \
    MISE_CACHE_DIR=/var/cache/mise \
    MISE_INSTALL_PATH=/usr/local/bin/mise \
    MISE_YES=1 \
    PATH=/usr/local/share/mise/shims:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Keep the base intentionally small. Browser binaries and project dependencies are
# installed from each consuming repository/lockfile, not baked independently here.
# hadolint ignore=DL3008
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        build-essential \
        ca-certificates \
        curl \
        git \
        git-lfs \
        gnupg \
        jq \
        libffi-dev \
        libpq-dev \
        libssl-dev \
        openssh-client \
        passwd \
        pkg-config \
        rsync \
        shellcheck \
        sudo \
        unzip \
        xz-utils \
        zip \
    && rm -rf /var/lib/apt/lists/*

# Pin and verify the mise installer itself before it downloads the pinned binary.
RUN curl --proto '=https' --proto-redir '=https' --tlsv1.2 \
        --fail --show-error --silent --location \
        "https://github.com/jdx/mise/releases/download/v${MISE_VERSION}/install.sh" \
        -o /tmp/install-mise.sh \
    && printf '%s  %s\n' "${MISE_INSTALLER_SHA256}" /tmp/install-mise.sh | sha256sum --check --strict \
    && MISE_VERSION="${MISE_VERSION}" sh /tmp/install-mise.sh \
    && rm -f /tmp/install-mise.sh \
    && mise --version

# Install shared language/tool runtimes. /usr/bin/python3 remains Ubuntu-owned;
# project commands resolve the mise shims first through PATH.
RUN mkdir -p /etc/mise /usr/local/share/mise /var/cache/mise \
    && printf '%s\n' \
        '[tools]' \
        "python = \"${PYTHON_VERSION}\"" \
        "node = \"${NODE_VERSION}\"" \
        "uv = \"${UV_VERSION}\"" \
        > /etc/mise/config.toml \
    && mise trust /etc/mise/config.toml \
    && mise install --system \
        "python@${PYTHON_VERSION}" \
        "node@${NODE_VERSION}" \
        "uv@${UV_VERSION}" \
    && mise exec "node@${NODE_VERSION}" -- npm install --global "npm@${NPM_VERSION}" \
    && mise reshim \
    && python --version \
    && uv --version \
    && node --version \
    && npm --version

# Docker client only: this image never starts dockerd and never exposes a daemon.
# A TrueNAS LXC must use either a reviewed remote builder or a separately reviewed
# privileged nested-Docker configuration. Never mount the TrueNAS host Docker socket.
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && source /etc/os-release \
    && printf 'deb [arch=%s signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu %s stable\n' \
        "$(dpkg --print-architecture)" "${VERSION_CODENAME}" \
        > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        docker-buildx-plugin \
        docker-ce-cli \
        docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/* \
    && docker --version \
    && docker buildx version \
    && docker compose version

RUN groupadd --gid "${RUNNER_GID}" runner \
    && useradd --uid "${RUNNER_UID}" --gid runner --create-home --shell /bin/bash runner \
    && printf 'runner ALL=(ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/runner \
    && chmod 0440 /etc/sudoers.d/runner \
    && mkdir -p /work /cache \
    && chown -R runner:runner /work /cache

USER runner
WORKDIR /work

# A consuming project owns its exact dependency graph. Typical use:
#   fastapi-sample: uv sync --locked && mise run agent-publish
#   nabla-site-alban: npm ci && npm run quality:agent:publish && npm run build
CMD ["bash"]
