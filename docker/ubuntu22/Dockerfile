# syntax=docker/dockerfile:1.7
FROM docker.io/ubuntu:22.04 as base
# FROM selenium/standalone-chrome:4.8.3-20230328 as base
# FROM selenium/standalone-chrome:4.11.0-20230801 as base

# dockerfile_lint - ignore
LABEL name="jm-ubuntu" vendor="jusmundi" version="0.1.1"

# SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# No interactive frontend during docker build
ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true

ARG UBUNTU_USER_HOME=${UBUNTU_USER_HOME:-/home/ubuntu}
ENV UBUNTU_USER_HOME=${UBUNTU_USER_HOME:-/home/ubuntu}

#Below HOME is needed to override seluser (selenium user)
ENV HOME=${UBUNTU_USER_HOME}

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
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
RUN apt-get -q update --fix-missing \
  && apt-get full-upgrade -y \
  && apt-get -q -o Dpkg::Options::="--force-confnew" --no-install-recommends install -y \
  git git-lfs rsync curl wget bash jq \
  apt-utils apt-transport-https ca-certificates software-properties-common \
  build-essential locales \
  bzip2 zip unzip tar xz-utils gpg-agent \
  gnupg2 tzdata \
  gettext-base \
  vim nano \
  net-tools iputils-ping dnsutils inetutils-traceroute \
  openssh-client ssh-askpass \
  libffi-dev libgit2-dev zlib1g-dev \
  make maven \
  lego \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

#TODO vault

# because of tzdata and the need of noninteractive
ENV TZ "Europe/Paris"
RUN echo "${TZ}" > /etc/timezone
RUN ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime && locale-gen en_US.UTF-8 \
    && dpkg-reconfigure --frontend noninteractive tzdata

FROM base as docker

ENV USER=${USER:-ubuntu}
ENV GROUP=${GROUP:-docker}
ENV UID=${UID:-1000}
ENV GID=${GID:-1000}

# hadolint ignore=SC2059
RUN printf "\033[1;32mFROM UID:GID: ${UID}:${GID} \033[0m\n" && \
  printf "\033[1;32mUBUNTU_USER_HOME: ${UBUNTU_USER_HOME} \033[0m\n" && \
  printf "\033[1;32mWITH user: ${USER}\ngroup: ${GROUP} \033[0m\n"

### DOCKER

# dockerfile_lint - ignore
ENV DOCKER_VERSION=${DOCKER_VERSION:-"20.10.21~3-0"}

# hadolint ignore=DL3006,DL4006
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
RUN add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
# Install Docker from Docker Inc. repositories.
RUN apt-get update -qq && apt-get --no-install-recommends install -qqy \
  docker-ce=5:${DOCKER_VERSION}~ubuntu-$(lsb_release -cs) \
  docker-ce-cli=5:${DOCKER_VERSION}~ubuntu-$(lsb_release -cs) \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# PODMAN

# hadolint ignore=DL3006,DL4006
RUN curl -fsSL https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_${VERSION_ID}/Release.key \
  | gpg --dearmor  \
  echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/devel_kubic_libcontainers_unstable.gpg] \
    https://download.opensuse.org/repositories/devel:kubic:libcontainers:unstable/Debian_Testing/ /" \
  | tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list

# RUN sed -i "s/# unqualified-search-registries.*/unqualified-search-registries\ =\ [\"docker.io\"]/" /etc/containers/registries.conf

# hadolint ignore=DL3008
#RUN apt-get -q update \
#  && apt-get -q -o Dpkg::Options::="--force-confnew" --no-install-recommends install -y \
#  && apt-get clean && rm -rf /var/lib/apt/lists/*

### USER (should follow ### DOCKER)

# Add user ubuntu to the image
RUN groupmod -g ${GID} ${GROUP} \
&& adduser --quiet --uid ${UID} --gid ${GID} \
  --home ${UBUNTU_USER_HOME} \
#  --no-create-home \
  --disabled-password \
  --gecos "" \
  ${USER} \
&& usermod -a -G ${GROUP} ${USER} \
&& chown -R ${USER}:${GROUP} ${UBUNTU_USER_HOME}

#USER ${USER}

FROM docker as python

### PYTHON

# checkov:skip=CKV_DOCKER_8:Ensure the last USER is not root
# hadolint ignore=DL3002
USER root

# hadolint ignore=DL3008
RUN apt-get -q update \
  && apt-get -q -o Dpkg::Options::="--force-confnew" --no-install-recommends install -y \
  python3-setuptools python3 python3-pip python3-dev python3-apt python3-poetry \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Keeps Python from generating .pyc files in the container
ENV PYTHONDONTWRITEBYTECODE=1

# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=off

# hadolint ignore=DL3006,DL4006
#RUN curl https://bootstrap.pypa.io/get-pip.py | python3.8
#RUN ls -lrta /usr/bin/pip
#RUN ls -lrta /usr/local/bin/pip
#RUN which pip
RUN ln -sv "$(which python3)" /usr/bin/python
RUN python3 -m pip install --no-cache-dir --upgrade pip==23.3.2 \
  && pip3 --version && python3 --version

### DOCKER COMPOSE

ENV DOCKER_COMPOSE_VERSION=${DOCKER_COMPOSE_VERSION:-1.29.2}

### ANSIBLE CORE

# Install Ansible inventory file.
RUN mkdir -p /etc/ansible
RUN printf "[local]\nlocalhost ansible_connection=local\n" > /etc/ansible/hosts

#RUN python3 -m pip install --proxy=${http_proxy} --no-cache-dir pipenv==2023.7.23 \
#  docker-compose==${DOCKER_COMPOSE_VERSION} ansible-core==2.13.12 \
#  && pip3 --version && python3 --version

RUN python3 -m pip install --proxy=${http_proxy} --no-cache-dir pipenv==2023.7.23 \
  ansible-core==2.13.12 \
  && pip3 --version && python3 --version

#RUN ln -sv "$(which pip3)" /usr/bin/pip \
#  && ln -sv "$(which pip3)" /usr/bin/pip3

#ENV PATH=/usr/local/bin:${PATH}

# dockerfile_lint - ignore
USER ${USER}

RUN pip3 install --user --no-cache-dir pipenv==2023.7.23

COPY --chown=${USER}:${GROUP} Pipfile Pipfile.lock ${UBUNTU_USER_HOME}/

ENV PATH=${UBUNTU_USER_HOME}/.local/bin/:${PATH}

WORKDIR ${UBUNTU_USER_HOME}

RUN python3 -m pipenv install --system --dev --site-packages --ignore-pipfile
# --system to prevent the creation of a virtualenv at all.

### PYTHON VENV

#FROM python as builder
#
#USER root
#
## hadolint ignore=DL3008
#RUN apt-get -q update \
#  && apt-get -q -o Dpkg::Options::="--force-confnew" --no-install-recommends install -y \
#  python3.8-venv\
#  && apt-get clean && rm -rf /var/lib/apt/lists/*
#
#RUN python3 -m venv /opt/venv
##Make sure we use the virtualenv:
#ENV PATH="/opt/venv/bin:$PATH"
#RUN pip3 install --no-cache-dir ansible
#
#FROM base
#
#COPY --from=builder /opt/venv /opt/venv
#ENV PATH="/opt/venv/bin:$PATH"

# PHP

# checkov:skip=CKV_DOCKER_8:Ensure the last USER is not root
# hadolint ignore=DL3002
USER root

ARG S6_OVERLAY_VERSION=3.1.2.1
ENV PHP_VERSION=7.4

# APACHE-PHP
# dockerfile_lint - ignore
# hadolint ignore=DL3008
RUN add-apt-repository -y ppa:ondrej/php && apt-get update && apt-get install -yq --no-install-recommends \
    apache2 php${PHP_VERSION} \
    php${PHP_VERSION}-tidy \
    php${PHP_VERSION}-dom \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-zip \
    php${PHP_VERSION}-pgsql \
    php${PHP_VERSION}-intl \
    php${PHP_VERSION}-imap \
    php${PHP_VERSION}-opcache \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-common \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# COMPOSER

ENV COMPOSER_ALLOW_SUPERUSER=1

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# NODE

# checkov:skip=CKV_DOCKER_8:Ensure the last USER is not root
# hadolint ignore=DL3002
USER root

# This is used by nuxt, its dependencies require OpenSSLv2 where node v18 uses OpenSSLv3
ENV NODE_OPTIONS="--openssl-legacy-provider"

# hadolint ignore=DL3008,DL3015,DL3006,DL4006
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get update && apt-get install --no-install-recommends -y nodejs=18* && apt-get clean && rm -rf /var/lib/apt/lists/* && \
    npm set progress=false && \
    npm config set depth 0;
RUN npm install -g npm@10.4.0 && apt-get purge -y npm
RUN npm -v && command -v npm # 8.12.2
RUN npm install -g yarn@1.22.19 dockerfile_lint@0.3.4 newman@5.2.2 newman-reporter-htmlextra@1.19.7 jest@28.1.0 jest-junit@14.0.1 && apt-get purge -y npm

# GO

# checkov:skip=CKV_DOCKER_8:Ensure the last USER is not root
# hadolint ignore=DL3002
USER root

ENV GO_VERSION=${GO_VERSION:-"1.19"}
ENV GO_FILENAME=go${GO_VERSION}.linux-amd64.tar.gz
ENV GO_URL=https://go.dev/dl/${GO_FILENAME}

RUN curl -L -o /tmp/${GO_FILENAME} ${GO_URL} \
  && tar -C /usr/local -xzf /tmp/${GO_FILENAME} \
  && rm -rf /tmp/*

#USER ${USER}

ENV GOROOT=/usr/local/go
ENV GOPATH=${UBUNTU_USER_HOME}/go
ENV GO111MODULE=on

RUN ${GOROOT}/bin/go install github.com/hashicorp/levant@main \
&& ${GOROOT}/bin/go install github.com/aquasecurity/tfsec/cmd/tfsec@latest \
&& ${GOROOT}/bin/go install github.com/minamijoyo/tfupdate@latest \
&& ${GOROOT}/bin/go install mvdan.cc/sh/v3/cmd/shfmt@latest \
&& ${GOROOT}/bin/go install github.com/cweill/gotests/gotests@latest

#RUN ls -lrta /home/ubuntu/.cache/go-build/
#RUN chown -R ${USER}:${GROUP} /home/ubuntu/go/ /home/ubuntu/.cache/

ENV PATH=${GOPATH}/bin:${GOROOT}/bin:${PATH}

# OPENJDK

# Install openjdk to allow to run the selenium driver. The mkdir is here to avoid an issue during the installation.
#RUN mkdir -p /usr/share/man/man1 && \
#    apt-get update && apt-get install -y openjdk-11-jdk \
#    && apt-get clean && rm -rf /var/lib/apt/lists/*

# NOMAD

ENV NOMAD_VERSION=${NOMAD_VERSION:-"1.6.2"}
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
RUN . /etc/os-release \
  && apt-get update \
  && apt-get -q -o Dpkg::Options::="--force-confnew" --no-install-recommends install -y \
  ca-certificates curl gnupg2 && \
  echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list && \
  curl -fsL "https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_${VERSION_ID}/Release.key" | apt-key add - && \
  apt-get update \
  && apt-get -q -o Dpkg::Options::="--force-confnew" --no-install-recommends install -y \
  buildah \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# TRIVY

ENV TRIVY_VERSION=${TRIVY_VERSION:-"v0.44.1"}
# hadolint ignore=DL3006,DL4006
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin ${TRIVY_VERSION}

# CODE CLIMATE

#RUN curl -L https://github.com/codeclimate/codeclimate/archive/master.tar.gz | tar xvz && \
#  cd codeclimate-* && sudo make install

# CST

# RUN curl -LO https://storage.googleapis.com/container-structure-test/latest/container-structure-test-linux-amd64 && chmod +x container-structure-test-linux-amd64 && mv container-structure-test-linux-amd64 /usr/local/bin/container-structure-test
RUN curl -LO https://storage.googleapis.com/container-structure-test/v1.16.0/container-structure-test-linux-amd64 && chmod +x container-structure-test-linux-amd64 && mv container-structure-test-linux-amd64 /usr/local/bin/container-structure-test

# DIVE

# checkov:skip=CKV_DOCKER_9:Ensure that APT isn't used
RUN curl -LO https://github.com/wagoodman/dive/releases/download/v0.9.2/dive_0.9.2_linux_amd64.deb && apt-get install --no-install-recommends -y ./dive_0.9.2_linux_amd64.deb && rm -f dive_0.9.2_linux_amd64.deb && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN chown -R ${USER}:${GROUP} "${UBUNTU_USER_HOME}/.npm"

# dockerfile_lint - ignore
USER ${USER}

WORKDIR ${UBUNTU_USER_HOME}

COPY --chown=${USER}:${GROUP} package*.json ${UBUNTU_USER_HOME}/
RUN npm install

WORKDIR /tmp

#FROM prebuild as build

# checkov:skip=CKV_DOCKER_8:Ensure the last USER is not root
# hadolint ignore=DL3002
USER root

RUN sed -i -e 's|^\[machine\]|#\[machine\]|g' /usr/share/containers/containers.conf

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

# RUN apt-get clean && rm -rf /var/lib/apt/lists/* && go clean -cache -modcache && rm -rf /home/ubuntu/.cache/ /home/ubuntu/go/pkg/mod/cache

# USER ${USER}

VOLUME /var/lib/docker

EXPOSE 2375 2376

ENTRYPOINT ["dockerd-entrypoint.sh"]
CMD ["/bin/bash"]

HEALTHCHECK NONE
