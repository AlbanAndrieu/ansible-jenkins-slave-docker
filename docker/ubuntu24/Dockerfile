# syntax=docker/dockerfile:1
# Selenium 4.52 is built on ubuntu:resolute (26.04 LTS).
# shortcut: dated tag without @sha256, the dockerfile_lint hook rejects digests; pin it once that hook is dropped
FROM selenium/standalone-chrome:4.52.0-20261101 AS base

# dockerfile_lint - ignore
LABEL name="nabla-ubuntu" vendor="nabla" version="2.0.10"
# dockerfile_lint requires these exact keys
# hadolint ignore=DL3048
LABEL Name="nabla-ubuntu" Version="2.0.10"

# SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# No interactive frontend during docker build
ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true

ARG UBUNTU_USER_HOME=${UBUNTU_USER_HOME:-/home/ubuntu}
ENV UBUNTU_USER_HOME=${UBUNTU_USER_HOME:-/home/ubuntu}

#Below HOME is needed to override seluser (selenium user)
ENV HOME=${UBUNTU_USER_HOME}

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV TERM="xterm-256color"

# checkov:skip=CKV_DOCKER_8:Ensure the last USER is not root
# hadolint ignore=DL3002
USER 0

# Enable retry logic for apt up to 10 times
# Configure apt to always assume Y
RUN echo "APT::Acquire::Retries \"10\";" > /etc/apt/apt.conf.d/80-retries \
&& echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

# BASE

# libffi-dev libgit2-dev needed for pip install dvc[s3]==1.11.6 pathspec==0.9.0
# openssh-client  needed for eval $(ssh-agent -s) and ssh-add
# build-essential has gcc, needed for python requirements

# hadolint ignore=DL3008
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt-get -q update --fix-missing \
  && apt-get full-upgrade -y \
  && apt-get -q -o Dpkg::Options::="--force-confnew" --no-install-recommends install -y \
  git rsync curl wget bash jq \
  apt-utils apt-transport-https ca-certificates software-properties-common \
  build-essential locales \
  bzip2 zip unzip tar xz-utils gpg-agent \
  gnupg2 tzdata \
  gettext-base \
  nano \
  net-tools iputils-ping bind9-dnsutils inetutils-traceroute \
  openssh-client \
  libffi-dev libgit2-dev zlib1g-dev libpq-dev \
  make maven \
  acl \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Dev

# hadolint ignore=DL3008
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt-get -q update --fix-missing \
  && apt-get full-upgrade -y \
  && apt-get -q -o Dpkg::Options::="--force-confnew" --no-install-recommends install -y \
  libcairo2 \
  libleptonica-dev libjpeg-dev libpng-dev libtiff-dev libwebp-dev \
  unpaper ocrmypdf \
  tesseract-ocr-nor tesseract-ocr-fra tesseract-ocr-deu tesseract-ocr-eng tesseract-ocr-spa \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# because of tzdata and the need of noninteractive
ENV TZ="Europe/Paris"
RUN echo "${TZ}" > /etc/timezone
RUN ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime && locale-gen en_US.UTF-8 \
    && dpkg-reconfigure --frontend noninteractive tzdata

FROM base AS docker

ENV USER=${USER:-ubuntu}
ENV GROUP=${GROUP:-ubuntu}
ENV UID=${UID:-2000}
ENV GID=${GID:-2000}

# hadolint ignore=SC2059
RUN printf "\033[1;32mFROM UID:GID: ${UID}:${GID} \033[0m\n" && \
  printf "\033[1;32mUBUNTU_USER_HOME: ${UBUNTU_USER_HOME} \033[0m\n" && \
  printf "\033[1;32mWITH user: ${USER}\ngroup: ${GROUP} \033[0m\n"

### DOCKER

# dockerfile_lint - ignore
ENV DOCKER_VERSION=${DOCKER_VERSION:-"29.9.3-1"}

# apt-key no longer exists on Ubuntu 26.04: the repository is signed-by its own key.
RUN install -m 0755 -d /etc/apt/keyrings \
  && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc \
  && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list

# Docker CLI and buildx only: no dockerd. Builds go to a remote rootless
# BuildKit, see compose.buildkit.yml.
# hadolint ignore=SC2046,DL3008
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt-get update -qq && apt-get --no-install-recommends install -qqy \
  docker-ce-cli=5:${DOCKER_VERSION}~ubuntu.26.04~$(lsb_release -cs) \
  docker-buildx-plugin \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

FROM docker AS python

### PYTHON

# checkov:skip=CKV_DOCKER_8:Ensure the last USER is not root
# hadolint ignore=DL3002
USER 0

# Ubuntu 26.04 LTS Python 3.14; no pip: Python tools come from uv.
# hadolint ignore=DL3008
RUN apt-get -q update \
  && apt-get -q -o Dpkg::Options::="--force-confnew" --no-install-recommends install -y \
  python3-setuptools python3 python3-dev python3-apt python3-venv \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED=1 \
    # prevents python creating .pyc files
    PYTHONDONTWRITEBYTECODE=1 \
    # https://python-poetry.org/docs/configuration/#using-environment-variables
    POETRY_VERSION=2.1.3 \
    POETRY_NO_INTERACTION=1 \
    # make poetry create the virtual environment in the project's root
    # it gets named `.venv`
    POETRY_VIRTUALENVS_IN_PROJECT=true

### UV

ENV UV_VERSION=${UV_VERSION:-"0.13.7"}
ENV UV_SHA256="c5221ff41b7892bfc223543883600125f6a47fe845093e0f5bdff4f359196d83"
# hadolint ignore=DL4006
RUN curl -fsSL -o /tmp/uv.tar.gz \
      https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-x86_64-unknown-linux-gnu.tar.gz \
  && echo "${UV_SHA256}  /tmp/uv.tar.gz" | sha256sum -c - \
  && tar -xzf /tmp/uv.tar.gz -C /usr/local/bin --strip-components=1 \
  && rm -f /tmp/uv.tar.gz \
  && uv --version

### ANSIBLE CORE, ANSIBLE LINT, PIPENV, POETRY

# Install Ansible inventory file.
RUN mkdir -p /etc/ansible
RUN printf "[local]\nlocalhost ansible_connection=local\n" > /etc/ansible/hosts

# Each tool gets its own environment on the system Python, outside the
# EXTERNALLY-MANAGED system site-packages. Downloads are refused only during
# the build, so jobs keep uv's default interpreter resolution.
ENV UV_TOOL_DIR=/opt/uv/tools \
    UV_TOOL_BIN_DIR=/usr/local/bin
RUN export UV_PYTHON_DOWNLOADS=never UV_NO_CACHE=1 \
  && uv tool install --python /usr/bin/python3 ansible-core==2.20.1 \
  && uv tool install --python /usr/bin/python3 ansible-lint==26.10.1 --with ansible-core==2.20.1 \
  && uv tool install --python /usr/bin/python3 pipenv==2025.0.4 \
  && uv tool install --python /usr/bin/python3 poetry=="${POETRY_VERSION}"

RUN ln -sfv "$(which python3)" /usr/bin/python

# PHP

# checkov:skip=CKV_DOCKER_8:Ensure the last USER is not root
# hadolint ignore=DL3002
USER 0

# s6 OVERLAY

# ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME=120000
# ENV S6_OVERLAY_VERSION=3.2.0.0
ENV DEBIAN_FRONTEND=noninteractive \
    S6_OVERLAY_VERSION=3.1.2.1 \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_VERBOSITY=1

ARG S6_OVERLAY_VERSION=3.2.0.0
# ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME=120000

ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz && rm -rf /tmp/s6*

# COPY oci/s6/apache2.sh /etc/s6-overlay/s6-rc.d/apache2/run
# RUN echo "longrun" > /etc/s6-overlay/s6-rc.d/apache2/type
# RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/apache2
#
# COPY oci/s6/php-fpm.sh /etc/s6-overlay/s6-rc.d/php-fpm/run
# RUN echo "longrun" > /etc/s6-overlay/s6-rc.d/php-fpm/type
# RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/php-fpm

# PHP

# Ubuntu 26.04 LTS PHP; dom, opcache, pdo and sockets are built in.
ENV PHP_VERSION=8.5

# APACHE-PHP
# dockerfile_lint - ignore
# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get install -yq --no-install-recommends \
    apache2 php${PHP_VERSION} \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-tidy \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-zip \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-pgsql \
    php${PHP_VERSION}-intl \
    php${PHP_VERSION}-apcu \
    php${PHP_VERSION}-redis \
    php${PHP_VERSION}-xdebug \
    php${PHP_VERSION}-sqlite3 \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ensure Apache does not start automatically and disable the default site
# hadolint ignore=DL3001
RUN service apache2 stop \
    && update-rc.d apache2 disable \
    && a2dissite 000-default.conf \
    && rm -rf /etc/apache2/sites-available/*

# Ensure apache2 will be able to start
RUN mkdir -p /var/run/apache2 && chmod 755 -R /var/run/apache2 && chown -R www-data:www-data /var/run/apache2
# Ensure php-fmp will be able to start
RUN mkdir -p /run/php/ || true
RUN chown -R www-data:www-data /run

# # PHP-FPM
# COPY oci/php.ini /etc/php/${PHP_VERSION}/fpm/php.ini
# COPY oci/pool-fpm.www.conf /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
#
# # Apache
# COPY oci/apache_ports.conf /etc/apache2/ports.conf
# COPY oci/apache_vhost.conf /etc/apache2/sites-available/000-default.conf
# COPY oci/status.conf /etc/apache2/mods-available/status.conf
# COPY oci/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini
# COPY oci/apache.conf /etc/apache2/conf-available/z-app.conf
# Cloudflare https://developers.cloudflare.com/support/troubleshooting/restoring-visitor-ips/restoring-original-visitor-ips/
# COPY oci/remoteip.conf /etc/apache2/conf-available/remoteip.conf
# COPY oci/fullchain.pem /etc/fullchain.pem
# COPY oci/privkey.pem /etc/privkey.pem

# COMPOSER

ENV APP_BASE_DIR=/var/www/html \
    APACHE_DOCUMENT_ROOT=/var/www/html \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/home/ubuntu \
    COMPOSER_MAX_PARALLEL_HTTP=24

# Composer
# dockerfile_lint - ignore
# hadolint ignore=DL4006
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# NODE

# checkov:skip=CKV_DOCKER_8:Ensure the last USER is not root
# hadolint ignore=DL3002
USER 0

# This is used by nuxt, its dependencies require OpenSSLv2 where node v20 uses OpenSSLv3
ENV NODE_OPTIONS="--openssl-legacy-provider"
ENV NODE_VERSION=${NODE_VERSION:-"26"}

# hadolint ignore=DL3008,DL3015,DL3006,DL4006
RUN curl -sL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    apt-get update && apt-get install --no-install-recommends -y nodejs=${NODE_VERSION}* && apt-get clean && rm -rf /var/lib/apt/lists/* && \
    npm set progress=false && \
    npm config set depth 0 && \
    apt-get purge -y npm

# GO

# checkov:skip=CKV_DOCKER_8:Ensure the last USER is not root
# hadolint ignore=DL3002
USER 0

ENV GO_VERSION=${GO_VERSION:-"1.25.5"}
ENV GO_FILENAME=go${GO_VERSION}.linux-amd64.tar.gz
ENV GO_URL=https://go.dev/dl/${GO_FILENAME}

RUN curl -L -o /tmp/${GO_FILENAME} ${GO_URL} \
  && tar -C /usr/local -xzf /tmp/${GO_FILENAME} \
  && rm -rf /tmp/*

#USER ${USER}

ENV GOROOT=/usr/local/go
ENV GOPATH=${UBUNTU_USER_HOME}/go
ENV GO111MODULE=on

RUN ${GOROOT}/bin/go install github.com/aquasecurity/tfsec/cmd/tfsec@latest \
&& ${GOROOT}/bin/go install github.com/minamijoyo/tfupdate@latest \
&& ${GOROOT}/bin/go install mvdan.cc/sh/v3/cmd/shfmt@latest \
&& ${GOROOT}/bin/go install github.com/cweill/gotests/gotests@latest

#RUN ls -lrta /home/ubuntu/.cache/go-build/
#RUN chown -R ${USER}:${GROUP} /home/ubuntu/go/ /home/ubuntu/.cache/

ENV PATH=${GOPATH}/bin:${GOROOT}/bin:${PATH}

# OPENJDK

# Install openjdk to allow to run the selenium driver. The mkdir is here to avoid an issue during the installation.
# hadolint ignore=DL3008
RUN mkdir -p /usr/share/man/man1 && \
    apt-get update && apt-get install -y --no-install-recommends openjdk-17-jdk \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# BUILDAH

# hadolint ignore=DL3008,SC1091,DL3006,DL4006
#RUN . /etc/os-release \
#  && apt-get update \
#  && apt-get -q -o Dpkg::Options::="--force-confnew" --no-install-recommends install -y \
#  ca-certificates curl gnupg2 && \
#  echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list && \
#  curl -fsL "https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_${VERSION_ID}/Release.key" | apt-key add - && \
#  apt-get update \
#  && apt-get -q -o Dpkg::Options::="--force-confnew" --no-install-recommends install -y \
#  buildah \
#  && apt-get clean && rm -rf /var/lib/apt/lists/*

# TRIVY

ENV TRIVY_VERSION=${TRIVY_VERSION:-"0.71.2"}
ENV TRIVY_SHA256="0510e71e2fd39bf863856d499c8dc19feb4e7336546394c502a8f5cc7ab27460"
RUN curl -sSL -o /tmp/html.tpl https://github.com/aquasecurity/trivy/raw/v${TRIVY_VERSION}/contrib/html.tpl
RUN curl -sSL -o /tmp/gitlab-codequality.tpl https://github.com/aquasecurity/trivy/raw/v${TRIVY_VERSION}/contrib/gitlab-codequality.tpl
# hadolint ignore=DL4006
RUN curl -fsSL -o /tmp/trivy.tar.gz \
      https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz \
  && echo "${TRIVY_SHA256}  /tmp/trivy.tar.gz" | sha256sum -c - \
  && tar -xzf /tmp/trivy.tar.gz -C /usr/local/bin trivy \
  && rm -f /tmp/trivy.tar.gz \
  && trivy --version

RUN mkdir -p /trivycache \
 && chown -R root. /trivycache \
 && find /trivycache -type d -exec chmod 755 '{}' \; \
 && find /trivycache -type f -exec chmod 644 '{}' \;

# CODE CLIMATE

# RUN curl -L https://github.com/codeclimate/codeclimate/archive/master.tar.gz | tar xvz && \
#  cd codeclimate-* && sudo make install

# CST

ENV CST_VERSION=${CST_VERSION:-"v1.16.0"}

# RUN curl -LO https://storage.googleapis.com/container-structure-test/latest/container-structure-test-linux-amd64 && chmod +x container-structure-test-linux-amd64 && mv container-structure-test-linux-amd64 /usr/local/bin/container-structure-test
RUN curl -LO https://storage.googleapis.com/container-structure-test/${CST_VERSION}/container-structure-test-linux-amd64 && chmod +x container-structure-test-linux-amd64 && mv container-structure-test-linux-amd64 /usr/local/bin/container-structure-test

# DIVE

# checkov:skip=CKV_DOCKER_9:Ensure that APT isn't used
# RUN curl -LO https://github.com/wagoodman/dive/releases/download/v0.9.2/dive_0.9.2_linux_amd64.deb && apt-get install --no-install-recommends -y ./dive_0.9.2_linux_amd64.deb && rm -f dive_0.9.2_linux_amd64.deb && apt-get clean && rm -rf /var/lib/apt/lists/*

# GITHUB ACTIONS RUNNER

# Self-hosted agent: nabla-compose apps/github-runner starts it with a one-time JIT config.
ENV ACTIONS_RUNNER_VERSION=${ACTIONS_RUNNER_VERSION:-"2.338.2"}
ENV ACTIONS_RUNNER_SHA256="baebf204307bac6193480852732f0aba2ae97b6c5597c244f4d5558390147c40"
# hadolint ignore=DL4006
RUN curl -fsSL -o /tmp/actions-runner.tar.gz \
      https://github.com/actions/runner/releases/download/v${ACTIONS_RUNNER_VERSION}/actions-runner-linux-x64-${ACTIONS_RUNNER_VERSION}.tar.gz \
  && echo "${ACTIONS_RUNNER_SHA256}  /tmp/actions-runner.tar.gz" | sha256sum -c - \
  && mkdir -p /opt/actions-runner \
  && tar -xzf /tmp/actions-runner.tar.gz -C /opt/actions-runner \
  && rm -f /tmp/actions-runner.tar.gz \
  && /opt/actions-runner/bin/installdependencies.sh \
  && apt-get clean && rm -rf /var/lib/apt/lists/* \
  && chown -R 1000:1000 /opt/actions-runner

USER 0

# the selenium base image lets every user sudo to root without a password
RUN sed -i '/^ALL ALL = (ALL) NOPASSWD: ALL$/d' /etc/sudoers \
  && visudo -c

# dockerfile_lint - ignore
USER 1000

WORKDIR /tmp

# GitHub Actions `container:` and Jenkins `agent { docker }` start their own
# command and UID: no entrypoint, no daemon, no root at runtime.
ENTRYPOINT []
CMD ["/bin/bash"]

HEALTHCHECK NONE
