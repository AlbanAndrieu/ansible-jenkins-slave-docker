# syntax=docker/dockerfile:1
# FROM docker.io/ubuntu:24.04 AS base
FROM selenium/standalone-chrome:4.25.0-20240922 AS base

# dockerfile_lint - ignore
LABEL name="nabla-ubuntu" vendor="nabla" version="2.0.10"

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
USER root

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
  net-tools iputils-ping dnsutils inetutils-traceroute \
  openssh-client ssh-askpass \
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
  libreoffice-writer libreoffice-calc libreoffice-impress unpaper ocrmypdf \
  tesseract-ocr-nor tesseract-ocr-fra tesseract-ocr-deu tesseract-ocr-eng tesseract-ocr-spa \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# because of tzdata and the need of noninteractive
ENV TZ="Europe/Paris"
RUN echo "${TZ}" > /etc/timezone
RUN ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime && locale-gen en_US.UTF-8 \
    && dpkg-reconfigure --frontend noninteractive tzdata

FROM base AS docker

ENV USER=${USER:-ubuntu}
ENV GROUP=${GROUP:-docker}
ENV UID=${UID:-2000}
ENV GID=${GID:-2000}

# hadolint ignore=SC2059
RUN printf "\033[1;32mFROM UID:GID: ${UID}:${GID} \033[0m\n" && \
  printf "\033[1;32mUBUNTU_USER_HOME: ${UBUNTU_USER_HOME} \033[0m\n" && \
  printf "\033[1;32mWITH user: ${USER}\ngroup: ${GROUP} \033[0m\n"

### DOCKER

# dockerfile_lint - ignore
ENV DOCKER_VERSION=${DOCKER_VERSION:-"28.3.3-1"}

# hadolint ignore=DL3006,DL4006
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
RUN add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"

# Install Docker from Docker Inc. repositories.
# hadolint ignore=SC2046,DL3008
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt-get update -qq && apt-get --no-install-recommends install -qqy \
  docker-ce=5:${DOCKER_VERSION}~ubuntu.24.04~$(lsb_release -cs) \
  docker-ce-cli=5:${DOCKER_VERSION}~ubuntu.24.04~$(lsb_release -cs) \
  docker-buildx-plugin \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# PODMAN

# hadolint ignore=DL3006,DL4006
# RUN curl -fsSL https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_${VERSION_ID}/Release.key \
#   | gpg --dearmor  \
#   echo \
#   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/devel_kubic_libcontainers_unstable.gpg] \
#     https://download.opensuse.org/repositories/devel:kubic:libcontainers:unstable/Debian_Testing/ /" \
#   | tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list

# RUN sed -i "s/# unqualified-search-registries.*/unqualified-search-registries\ =\ [\"docker.io\"]/" /etc/containers/registries.conf

### USER (should follow ### DOCKER)

# Add user ubuntu to the image
# RUN groupmod -g ${GID} ${GROUP} \
# && adduser --quiet --uid ${UID} --gid ${GID} \
#   --home ${UBUNTU_USER_HOME} \
#   --disabled-password \
#   --gecos "" \
#   ${USER} \
# && usermod -a -G ${GROUP} ${USER} \
# && chown -R ${USER}:${GROUP} ${UBUNTU_USER_HOME}

#USER ${USER}

FROM docker AS python

### PYTHON

# checkov:skip=CKV_DOCKER_8:Ensure the last USER is not root
# hadolint ignore=DL3002
USER root

# hadolint ignore=DL3008
RUN apt-get -q update \
  && apt-get -q -o Dpkg::Options::="--force-confnew" --no-install-recommends install -y \
  python3-setuptools python3 python3-pip python3-dev python3-apt python3-venv \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

### OLDER PYTHON 3.10

# dockerfile_lint - ignore
# hadolint ignore=DL3008
RUN add-apt-repository -y ppa:deadsnakes/ppa && apt-get update && \
  apt-get install -yq --no-install-recommends \
  python3.10 \
  python3.10-dev \
  python3.10-venv \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

#RUN python3.10 -m venv /opt/venv
##Make sure we use the virtualenv:
#ENV PATH="/opt/venv/bin:$PATH"
#RUN pip3 install --no-cache-dir ansible

#COPY --from=builder /opt/venv /opt/venv
#ENV PATH="/opt/venv/bin:$PATH"

### PYTHON POETRY

# Turns off buffering for easier container logging
# python
ENV PYTHONUNBUFFERED=1 \
    # prevents python creating .pyc files
    PYTHONDONTWRITEBYTECODE=1 \
    # pip
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    # poetry
    # https://python-poetry.org/docs/configuration/#using-environment-variables
    POETRY_VERSION=2.1.3 \
    # make poetry install to this location
    POETRY_HOME="/opt/poetry" \
    POETRY_NO_INTERACTION=1 \
    # make poetry create the virtual environment in the project's root
    # it gets named `.venv`
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    # do not ask any interactive question
    POETRY_NO_INTERACTION=1 \
    # paths
    # this is where our requirements + virtual environment will live
    PYSETUP_PATH="/opt/pysetup"

# Installs Poetry in its own environment to avoid problems with Ubuntu's Python
# hadolint ignore=SC2086
RUN --mount=type=cache,target=/root/.cache/pip \
  python3 -m venv "${POETRY_HOME}" \
  && "${POETRY_HOME}/bin/pip" install --no-cache-dir --upgrade pip==26.0.1 \
  && "${POETRY_HOME}/bin/pip" install poetry=="${POETRY_VERSION}" \
  && "${POETRY_HOME}/bin/poetry" --version

### DOCKER COMPOSE

ENV DOCKER_COMPOSE_VERSION=${DOCKER_COMPOSE_VERSION:-2.27.0}

### ANSIBLE CORE

# Install Ansible inventory file.
RUN mkdir -p /etc/ansible
RUN printf "[local]\nlocalhost ansible_connection=local\n" > /etc/ansible/hosts

RUN --mount=type=cache,target=/root/.cache/pip \
  rm /usr/lib/python*/EXTERNALLY-MANAGED && \
  pip3 install --proxy=${http_proxy} --no-cache-dir pipenv==2025.0.4 \
  ansible-core==2.17.14

RUN ln -sv "$(which python3)" /usr/bin/python

# python3 -m pip install --no-cache-dir --break-system-packages --upgrade pip==26.0.1 && \

# dockerfile_lint - ignore
USER ${USER}

RUN pip3 install --user --no-cache-dir pipenv==2025.0.4

COPY --chown=${USER}:${GROUP} Pipfile Pipfile.lock ${UBUNTU_USER_HOME}/

ENV PATH=${UBUNTU_USER_HOME}/.local/bin/:${PATH}

WORKDIR ${UBUNTU_USER_HOME}

RUN python3 -m pipenv install --system --dev --site-packages --ignore-pipfile
# --system to prevent the creation of a virtualenv at all.

# PHP

# checkov:skip=CKV_DOCKER_8:Ensure the last USER is not root
# hadolint ignore=DL3002
USER root

ENV PHP_VERSION=8.2

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

ENV PHP_VERSION=7.4

# APACHE-PHP
# dockerfile_lint - ignore
# hadolint ignore=DL3008
RUN add-apt-repository -y ppa:ondrej/php && apt-get update && \
    apt-get install -yq --no-install-recommends \
    apache2 php${PHP_VERSION} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# hadolint ignore=DL3008
RUN add-apt-repository -y ppa:ondrej/php && apt-get update && \
    apt-get install -yq --no-install-recommends \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-tidy \
    php${PHP_VERSION}-dom \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-zip \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-pgsql \
    php${PHP_VERSION}-intl \
    php${PHP_VERSION}-sockets \
    php${PHP_VERSION}-opcache \
    php${PHP_VERSION}-apcu \
    php${PHP_VERSION}-pdo \
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
USER root

# This is used by nuxt, its dependencies require OpenSSLv2 where node v20 uses OpenSSLv3
ENV NODE_OPTIONS="--openssl-legacy-provider"
ENV NODE_VERSION=${NODE_VERSION:-"25"}

# hadolint ignore=DL3008,DL3015,DL3006,DL4006
RUN curl -sL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    apt-get update && apt-get install --no-install-recommends -y nodejs=${NODE_VERSION}* && apt-get clean && rm -rf /var/lib/apt/lists/* && \
    npm set progress=false && \
    npm config set depth 0 && \
    npm install -g npm@11.6.0 && apt-get purge -y npm

# GO

# checkov:skip=CKV_DOCKER_8:Ensure the last USER is not root
# hadolint ignore=DL3002
USER root

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

RUN curl -L https://github.com/hashicorp/levant/releases/download/0.2.9/linux-amd64-levant -o levant

RUN ${GOROOT}/bin/go install github.com/aquasecurity/tfsec/cmd/tfsec@latest \
&& ${GOROOT}/bin/go install github.com/minamijoyo/tfupdate@latest \
&& ${GOROOT}/bin/go install mvdan.cc/sh/v3/cmd/shfmt@latest \
&& ${GOROOT}/bin/go install github.com/cweill/gotests/gotests@latest

#RUN ls -lrta /home/ubuntu/.cache/go-build/
#RUN chown -R ${USER}:${GROUP} /home/ubuntu/go/ /home/ubuntu/.cache/

ENV PATH=${GOPATH}/bin:${GOROOT}/bin:${PATH}

# OPENJDK

# Install openjdk to allow to run the selenium driver. The mkdir is here to avoid an issue during the installation.
RUN mkdir -p /usr/share/man/man1 && \
    apt-get update && apt-get install -y --no-install-recommends openjdk-17-jdk \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# NOMAD

ENV NOMAD_VERSION=${NOMAD_VERSION:-"1.11.0"}
ENV NOMAD_FILENAME=nomad_${NOMAD_VERSION}_linux_amd64.zip
ENV NOMAD_URL=https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/${NOMAD_FILENAME}

# checkov:skip=CKV_DOCKER_8:Ensure the last USER is not root
# hadolint ignore=DL3002
USER root

RUN curl -L -o /tmp/${NOMAD_FILENAME} ${NOMAD_URL} \
  && unzip /tmp/${NOMAD_FILENAME} -d /tmp \
  && chmod +x /tmp/nomad \
  && mv /tmp/nomad /bin/nomad \
  && rm -rf /tmp/*

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

ENV TRIVY_VERSION=${TRIVY_VERSION:-"0.69.0"}
RUN curl -sSL -o /tmp/html.tpl https://github.com/aquasecurity/trivy/raw/v${TRIVY_VERSION}/contrib/html.tpl
RUN curl -sSL -o /tmp/gitlab-codequality.tpl https://github.com/aquasecurity/trivy/raw/v${TRIVY_VERSION}/contrib/gitlab-codequality.tpl
# hadolint ignore=DL3006,DL4006
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v${TRIVY_VERSION}

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

WORKDIR ${UBUNTU_USER_HOME}

COPY --chown=${USER}:${GROUP} package*.json ${UBUNTU_USER_HOME}/

USER root

# hadolint ignore=SC2121
RUN --mount=type=cache,target=/root/.npm \
  set npm_config_cache="${UBUNTU_USER_HOME}/.npm" && npm cache clean --force && npm set progress=false \
  && npm install --save-dev \
  && npm cache clean --force

RUN chown -R ${USER}:${GROUP} "${UBUNTU_USER_HOME}/.npm"

# dockerfile_lint - ignore
USER ${USER}

WORKDIR /tmp

# checkov:skip=CKV_DOCKER_8:Ensure the last USER is not root
# hadolint ignore=DL3002
USER root

# RUN sed -i -e 's|^\[machine\]|#\[machine\]|g' /usr/share/containers/containers.conf

COPY modprobe.sh /usr/local/bin/modprobe
COPY dockerd-entrypoint.sh /usr/local/bin/

# https://github.com/docker-library/docker/pull/166
#   dockerd-entrypoint.sh uses DOCKER_TLS_CERTDIR for auto-generating TLS certificates
#   dockerd-entrypoint.sh uses DOCKER_TLS_CERTDIR for auto-setting DOCKER_TLS_VERIFY and DOCKER_CERT_PATH
# (For this to work, at least the "client" subdirectory of this path needs to be shared between the client and server containers via a volume, "docker cp", or other means of data sharing.)
ENV DOCKER_TLS_CERTDIR=/certs
# also, ensure the directory pre-exists and has wide enough permissions for "dockerd-entrypoint.sh" to create subdirectories, even when run in "rootless" mode
RUN mkdir /certs /certs/client && chmod 1777 /certs /certs/client
# (doing both /certs and /certs/client so that if Docker does a "copy-up" into a volume defined on /certs/client, it will "do the right thing" by default in a way that still works for rootless users)

RUN chmod +x /usr/local/bin/dockerd-entrypoint.sh /usr/local/bin/modprobe

VOLUME /var/lib/docker

EXPOSE 2375 2376

ENTRYPOINT ["dockerd-entrypoint.sh"]
CMD ["/bin/bash"]

HEALTHCHECK NONE
