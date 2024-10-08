# syntax=docker/dockerfile:1.7

# This Dockerfile is used to build an image containing basic stuff to be used as a Jenkins slave build node.
# Multistage build is not possible with Jenkins Docker Pipeline Plugin
# FROM ubuntu:24.10
# See https://github.com/SeleniumHQ/docker-selenium/blob/4.8.3-20230328/Base/Dockerfile
FROM selenium/standalone-chrome:4.11.0-20230801 as base

# dockerfile_lint - ignore
LABEL name="ansible-jenkins-slave" version="2.0.7" \
 description="Image used by our products to build Java/Javascript and CPP\
 this image is running on Ubuntu 20.10." \
 com.nabla.vendor="NABLA Incorporated"

# SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG UBUNTU_USER_HOME=${UBUNTU_USER_HOME:-/home/ubuntu}
ENV UBUNTU_USER_HOME=${UBUNTU_USER_HOME:-/home/ubuntu}
ARG JENKINS_USER_HOME=${JENKINS_USER_HOME:-/home/jenkins}
ENV JENKINS_USER_HOME=${JENKINS_USER_HOME:-/home/jenkins}

# ENV http_proxy=${http_proxy:-""}
# #ENV http_proxy=${http_proxy:-"http://127.0.0.1:3128"}
# #ENV http_proxy=${http_proxy:-"http://10.21.185.171:3128"}
# ENV https_proxy=${https_proxy:-"${http_proxy}"}
# ENV no_proxy=${no_proxy:-"localhost,127.0.0.1,.albandrieu.com,.azure.io,albandri,albandrieu,10.199.52.11,.github.com,.docker.com,.ubuntu.com"}

# No interactive frontend during docker build
ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true

#Below HOME is needed to override seluser (selenium user)
ENV HOME=${JENKINS_USER_HOME}
ENV JAVA_HOME="/usr/lib/jvm/java-1.8.0-openjdk-amd64"

ENV CHROME_BIN=/usr/bin/google-chrome
ENV CHROMIUM_BIN=/usr/bin/chromium-browser

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV TERM="xterm-256color"

# checkov:skip=CKV_DOCKER_8:Ensure the last USER is not root
# hadolint ignore=DL3002
USER root

#See https://github.com/actions/virtual-environments/blob/main/images/linux/scripts/base/apt.sh

# Stop and disable apt-daily upgrade services;
#systemctl stop apt-daily.timer
#systemctl disable apt-daily.timer
#systemctl disable apt-daily.service
#systemctl stop apt-daily-upgrade.timer
#systemctl disable apt-daily-upgrade.timer
#systemctl disable apt-daily-upgrade.service

#RUN echo "Acquire::http::Proxy \"${http_proxy}\";" > /etc/apt/apt.conf.d/proxy.conf

# Enable retry logic for apt up to 10 times
# Configure apt to always assume Y
RUN echo "APT::Acquire::Retries \"10\";" > /etc/apt/apt.conf.d/80-retries \
&& echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

# Uninstall unattended-upgrades
#RUN apt-get purge unattended-upgrades

# BASE

# libffi-dev libgit2-dev needed for pip install dvc[s3]==1.11.6 pathspec==0.9.0
# openssh-client  needed for eval $(ssh-agent -s) and ssh-add
# build-essential has gcc, needed for python requirements

# hadolint ignore=DL3008
RUN apt-get -q update --fix-missing \
  && apt-get full-upgrade -y \
  && apt-get -q -o Dpkg::Options::="--force-confnew" --no-install-recommends install -y \
  git rsync curl wget bash jq \
  python-yaml python-jinja2 rsyslog \
  ocl-icd-libopencl1 ocl-icd-opencl-dev clinfo numactl libnuma1 pciutils \
  apt-utils apt-transport-https ca-certificates software-properties-common \
  build-essential locales \
  bzip2 zip unzip tar xz-utils gpg-agent \
#  iptables supervisor sudo lsof \
  gnupg2 tzdata \
  gettext-base pass sshpass \
  systemd systemd-cron \
  maven gcc g++ make cmake \
  net-tools iputils-ping dnsutils inetutils-traceroute \
  openssh-client ssh-askpass \
  gnome-keyring gnome-keyring \
  x11-apps libxss1 \
  libnss3 \
  libffi-dev libgit2-dev zlib1g-dev \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

#  git-lfs vim lego

#TODO vault
# because of tzdata and the need of noninteractive
ENV TZ "Europe/Paris"
RUN echo "${TZ}" > /etc/timezone
RUN ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime && locale-gen en_US.UTF-8 \
    && dpkg-reconfigure --frontend noninteractive tzdata

# Remove unnecessary getty and udev targets that result in high CPU usage when using
# multiple containers with Molecule (https://github.com/ansible/molecule/issues/1104)
RUN rm -f /lib/systemd/system/systemd*udev* \
  && rm -f /lib/systemd/system/getty.target

FROM base as docker

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
ENV DOCKER_VERSION=${DOCKER_VERSION:-"20.10.21~3-0"}

# hadolint ignore=DL3006,DL4006
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
RUN add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
# Install Docker from Docker Inc. repositories.
# hadolint ignore=SC2046
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
RUN apt-get -q update \
  && apt-get -q -o Dpkg::Options::="--force-confnew" --no-install-recommends install -y \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# PODMAN

#ENV DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${UID}/bus
RUN printenv DBUS_SESSION_BUS_ADDRESS

# Add user ubuntu to the image
# Set password for the ubuntu user (you may want to alter this).
# Add the ubuntu user to sudoers
RUN groupmod -g ${GID} ${GROUP} \
&& adduser --quiet --uid ${UID} --gid ${GID} \
  --home ${UBUNTU_USER_HOME} \
#  --no-create-home \
  --disabled-password \
  --gecos "" \
  ${USER} \
&& usermod -a -G ${GROUP} ${USER} \
&& chown -R ${USER}:${GROUP} ${UBUNTU_USER_HOME}

#RUN cat /etc/group | grep docker || true
#RUN id docker
#RUN getent passwd 2000 || true

#RUN groupadd -g ${GID} ${GROUP} && \
&& adduser --quiet --uid 2000--gid $2000 --home ${JENKINS_USER_HOME} jenkins \
&& echo "jenkins:jenkins1234" | chpasswd \
&& usermod -a -G jenkins jenkins
# && echo "${USER}    ALL=(ALL)    ALL" >> /etc/sudoers

# hadolint ignore=SC2059
RUN curl -SsL https://github.com/boxboat/fixuid/releases/download/v0.4/fixuid-0.4-linux-amd64.tar.gz | tar -C /usr/local/bin -xzf - && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid && \
    printf "user: $USER\ngroup: $GROUP\n" > /etc/fixuid/config.yml

FROM docker as python

### PYTHON POETRY

# checkov:skip=CKV_DOCKER_8:Ensure the last USER is not root
# hadolint ignore=DL3002
USER root

# hadolint ignore=DL3008
RUN apt-get -q update \
  && apt-get -q -o Dpkg::Options::="--force-confnew" --no-install-recommends install -y \
  python3-setuptools python3 python3-pip python3-dev python3-apt python3-poetry \
  python3-lxml \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# python3-poetry

# Keeps Python from generating .pyc files in the container

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
    POETRY_VERSION=1.7.1 \
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
#     VENV_PATH="/code/.venv"
#     VIRTUAL_ENV="${UBUNTU_USER_HOME}/.venv"


# hadolint ignore=DL3006,DL4006
RUN curl https://bootstrap.pypa.io/get-pip.py | python3.8
#RUN ls -lrta /usr/bin/pip
#RUN ls -lrta /usr/local/bin/pip
#RUN which pip
RUN ln -sv "$(which python3)" /usr/bin/python
RUN python3 -m pip install --proxy="${http_proxy}" --no-cache-dir --upgrade pip==24.0 \
#  && ln -sv "$(which pip3)" /usr/bin/pip3 \
  && pip3 --version && python3 --version

### DOCKER COMPOSE

ENV DOCKER_COMPOSE_VERSION=${DOCKER_COMPOSE_VERSION:-2.26.1}
#RUN curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
#	&& chmod +x /usr/local/bin/docker-compose && docker-compose version

RUN python3 -m pip install --proxy="${http_proxy}" --no-cache-dir pipenv==2023.12.0 \
  docker-compose==${DOCKER_COMPOSE_VERSION} ansible-core==2.16.6 zabbix-api==0.5.4 \
  # awscli>=1.25.34 flake8>=4.0.1 semgrep>=0.94.0 pre-commit>=2.19.0 sphinx==2.3.1 \
  && pip3 --version && python3 --version

RUN ln -sv "$(which pip3)" /usr/bin/pip \
  && ln -sv "$(which pip3)" /usr/bin/pip3

#ENV PATH=/usr/local/bin:${PATH}

# dockerfile_lint - ignore
USER ${USER}

RUN pip3 install --user --no-cache-dir pipenv==2023.12.0

COPY --chown=${USER}:${GROUP} Pipfile Pipfile.lock ${UBUNTU_USER_HOME}/
RUN cd ${UBUNTU_USER_HOME} && python -m pipenv install --system --dev # --site-packages
# --system to prevent the creation of a virtualenv at all.

ENV PATH=${UBUNTU_USER_HOME}/.local/bin/:${PATH}

WORKDIR ${UBUNTU_USER_HOME}

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
# hadolint ignore=DL4006
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# NODE

# checkov:skip=CKV_DOCKER_8:Ensure the last USER is not root
# hadolint ignore=DL3002
USER root

# This is used by nuxt, its dependencies require OpenSSLv2 where node v18 uses OpenSSLv3
ENV NODE_OPTIONS="--openssl-legacy-provider"

# hadolint ignore=DL3008,DL3015,DL3006,DL4006
RUN curl -sL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get update && apt-get install --no-install-recommends -y nodejs=20* && apt-get clean && rm -rf /var/lib/apt/lists/* && \
    npm set progress=false && \
    npm config set depth 0;

RUN npm install -g npm@10.4.0 && apt-get purge -y npm
RUN npm -v && command -v npm # 9.5.0
RUN npm install -g bower@1.8.13 grunt@1.5.3 webdriver-manager@12.1.8 yarn@1.22.19 yo@latest shrinkwrap@0.4.0 json2csv@4.3.3 phantomas@1.20.1 dockerfile_lint@0.3.4 newman@5.2.2 newman-reporter-htmlextra@1.19.7 jest@28.1.0 storybook@8.1.9 jest-junit@14.0.1 xunit-viewer@5.1.11 bower-nexus3-resolver@1.0.2

### ANSIBLE

# Install Ansible inventory file.
RUN mkdir -p /etc/ansible
RUN printf "[local]\nlocalhost ansible_connection=local" > /etc/ansible/hosts
ENV ANSIBLE_CONFIG=${UBUNTU_USER_HOME}/ansible.cfg

ARG ANSIBLE_VAULT_PASSWORD
ENV ANSIBLE_VAULT_PASSWORD=${ANSIBLE_VAULT_PASSWORD:-"microsoft"}
RUN echo "${ANSIBLE_VAULT_PASSWORD}" > $UBUNTU_USER_HOME/vault.passwd && cat $UBUNTU_USER_HOME/vault.passwd
#COPY ansible.cfg $UBUNTU_USER_HOME/
COPY *.yml $UBUNTU_USER_HOME/
#COPY roles $UBUNTU_USER_HOME/
COPY inventory $UBUNTU_USER_HOME/inventory
COPY playbooks $UBUNTU_USER_HOME/playbooks
RUN rm -Rf $UBUNTU_USER_HOME/.ansible/roles/
COPY package.json $UBUNTU_USER_HOME/
# hadolint ignore=SC2046
RUN chown ${USER}:$(id -gn ${GROUP}) $UBUNTU_USER_HOME $UBUNTU_USER_HOME/.*

# Execute
#python36,brew are adding 2.7 G to the images

# hadolint ignore=DL3008,DL3015
RUN ansible-galaxy collection install -r "$UBUNTU_USER_HOME/requirements.yml" --force
RUN ansible-galaxy install -r "$UBUNTU_USER_HOME/requirements.yml" -p "$UBUNTU_USER_HOME/.ansible/roles/" --ignore-errors
RUN ansible-playbook "$UBUNTU_USER_HOME/playbooks/jenkins-slave-docker.yml" -i "$UBUNTU_USER_HOME/inventory/hosts" -c local \
 -e "workspace=/tmp" \
 -e "jenkins_jdk8_enable=true" \
# -e "jenkins_ssh_key_file={{ jenkins_home }}/.ssh/id_rsa" \
# -e "jdk_home=/usr/lib/jvm/java-8-openjdk-amd64/" \
 -e "jenkins_id=${UID}" -e "docker_gid=${GID}" \
 -e "nis_enabled=false" -e "automount_enabled=false" -e "dns_enabled=false" \
 -e "python_enabled=false" \
 -e "ansible_python_interpreter=/usr/bin/python3.8" \
 --skip-tags=restart,vm,python35,python36,python37,venv,requirements,brew,objc,kubernetes,nodejs,clang \
 --vault-id $UBUNTU_USER_HOME/vault.passwd \
 -vvvv \
 && apt-get autoremove -y && apt-get clean && apt-get remove asciidoc -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/man/* /var/log/* "$UBUNTU_USER_HOME/roles" "$UBUNTU_USER_HOME/playbooks" "$UBUNTU_USER_HOME/inventory" "$UBUNTU_USER_HOME/vault.passwd" "$UBUNTU_USER_HOME/ansible.log" "$UBUNTU_USER_HOME/requirements-*.txt" \
 && rm -Rf $UBUNTU_USER_HOME/playbooks/.node_cache/ \
 && rm -Rf $UBUNTU_USER_HOME/.cpan $UBUNTU_USER_HOME/.ansible \
 && rm -Rf $UBUNTU_USER_HOME/.npm $UBUNTU_USER_HOME/.node_cache $UBUNTU_USER_HOME/.cache/pip \
# && rm -Rf $UBUNTU_USER_HOME/.local/share \
 && chown -R "${USER}:$(id -gn ${GROUP})" "$UBUNTU_USER_HOME" && chmod -R 777 "${UBUNTU_USER_HOME}"

#/usr/bin/python3.7 -m pip install --no-cache-dir --upgrade pip

# hadolint ignore=SC2261
RUN python3 -m pip install --proxy="${http_proxy}" --no-cache-dir --upgrade pip==23.2.1 \
    && pip install --proxy="${http_proxy}" --no-cache-dir ansible-core>=2.13.0 docker-compose==1.29.2 pre-commit==2.20.0 ansible-lint-junit>=0.15 \
    && pip3 --version && python3 --version

RUN ifconfig | awk '/inet addr/{print substr($2,6)}' ## Display IP address (optional)

# GO

# checkov:skip=CKV_DOCKER_8:Ensure the last USER is not root
# hadolint ignore=DL3002
USER root

ENV GO_VERSION=${GO_VERSION:-"1.22.4"}
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
RUN mkdir -p /usr/share/man/man1 && \
    apt-get update && apt-get install -y --no-install-recommends openjdk-8-jdk openjdk-17-jdk \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ENV JAVA_HOME=${JAVA_HOME:-""/usr/lib/jvm/java-1.17.0-openjdk-amd64""}

# NOMAD

ENV NOMAD_VERSION=${NOMAD_VERSION:-"1.6.6"}
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

### HELM

ENV HELM_VERSION=${HELM_VERSION:-"v3.5.4"}
ENV HELM_FILENAME=helm-${HELM_VERSION}-linux-amd64.tar.gz
ENV HELM_URL=https://get.helm.sh/${HELM_FILENAME}

# Kubernetes tools
# hadolint ignore=DL3020
#ADD ${HELM_URL} /tmp/${HELM_FILENAME}
RUN curl -L -o /tmp/${HELM_FILENAME} ${HELM_URL} \
  && tar -zxvf /tmp/${HELM_FILENAME} -C /tmp \
  && chmod +x /tmp/linux-amd64/helm \
  && mv /tmp/linux-amd64/helm /bin/helm \
  && rm -rf /tmp/*

#RUN curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

ENV KUBECTL_VERSION=${KUBECTL_VERSION:-"v1.18.3"}
ENV KUBECTL_URL=https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl

# hadolint ignore=DL3020
#ADD ${KUBECTL_URL} /tmp/kubectl
RUN curl -L -o /tmp/kubectl ${KUBECTL_URL} \
  && chmod +x /tmp/kubectl \
  && mv /tmp/kubectl /bin/kubectl \
  && rm -rf /tmp/*

ENV SKAFFOLD_URL=https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64

#ADD https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64 skaffold
RUN curl -L -o /tmp/skaffold ${SKAFFOLD_URL} \
  && chmod +x /tmp/skaffold && mv /tmp/skaffold /usr/local/bin \
  && skaffold version \
  && rm -rf /tmp/*

### DRAFT

#ENV DRAFT_VERSION v0.16.0
#ENV DRAFT_FILENAME draft-${DRAFT_VERSION}-linux-amd64.tar.gz
#ENV DRAFT_URL https://azuredraft.blob.core.windows.net/draft/${DRAFT_FILENAME}
#
## hadolint ignore=DL3020
#RUN curl -L -o /tmp/${DRAFT_FILENAME} ${DRAFT_URL} \
#  && tar -zxvf /tmp/${DRAFT_FILENAME} -C /tmp \
#  && chmod +x /tmp/linux-amd64/draft \
#  && mv /tmp/linux-amd64/draft /bin/draft \
#  && draft init \
#  && bash -c "echo \"y\" | draft pack-repo remove github.com/Azure/draft" \
#  && rm -rf /tmp/* \
#  && chmod -R 777 ${UBUNTU_USER_HOME}/.draft && ls -lrta ${UBUNTU_USER_HOME}/.draft/plugins/  # for .draft/plugins

ARG AGENT_VERSION=${AGENT_VERSION:-"4.3"}
ARG AGENT_WORKDIR=${UBUNTU_USER_HOME}/agent

RUN curl --create-dirs -fsSLo /usr/share/jenkins/agent.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${AGENT_VERSION}/remoting-${AGENT_VERSION}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/agent.jar \
  && ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar

COPY jenkins-agent.sh /usr/local/bin/jenkins-agent
RUN chmod +x /usr/local/bin/jenkins-agent && \
    ln -s /usr/local/bin/jenkins-agent /usr/local/bin/jenkins-slave

ENV AGENT_WORKDIR=${AGENT_WORKDIR}
RUN mkdir ${JENKINS_USER_HOME}/.jenkins && mkdir -p ${AGENT_WORKDIR}

ENV HELM_FILE_VERSION=${HELM_FILE_VERSION:-"v0.144.0"}

# checkov:skip=CKV_DOCKER_4:Ensure that COPY is used instead of ADD in Dockerfiles
ADD https://github.com/roboll/helmfile/releases/download/${HELM_FILE_VERSION}/helmfile_linux_amd64 /usr/local/bin/helmfile
#sudo cp helmfile_linux_amd64 /usr/local/bin/helmfile
RUN chmod +x /usr/local/bin/helmfile

ENV HELM_DOC_VERSION=${HELM_DOC_VERSION:-"1.5.0"}

ADD https://github.com/norwoodj/helm-docs/releases/download/v${HELM_DOC_VERSION}/helm-docs_${HELM_DOC_VERSION}_linux_amd64.deb /tmp/helm-docs_${HELM_DOC_VERSION}_linux_amd64.deb
RUN dpkg -i /tmp/helm-docs_${HELM_DOC_VERSION}_linux_amd64.deb && rm -rf /tmp/*

ADD https://github.com/instrumenta/kubeval/releases/latest/download/kubeval-linux-amd64.tar.gz /tmp/kubeval-linux-amd64.tar.gz
RUN tar xf /tmp/kubeval-linux-amd64.tar.gz && cp kubeval /usr/local/bin && rm -rf /tmp/*

# hadolint ignore=SC2046
RUN chown -R jenkins:$(id -gn jenkins) $HOME $HOME/.*

#RUN chmod go-r $HOME/.kube/config

ENV WEBDRIVER_CHROME_VERSION=${WEBDRIVER_CHROME_VERSION:-"103.0.5060.134"}
#RUN webdriver-manager update --versions.chrome ${WEBDRIVER_CHROME_VERSION}
RUN webdriver-manager update

RUN sed -i -e 's|^\[machine\]|#\[machine\]|g' /usr/share/containers/containers.conf

COPY modprobe.sh /usr/local/bin/modprobe
COPY dockerd-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/dockerd-entrypoint.sh /usr/local/bin/modprobe

# Below for jenkins-slave-startup.sh
COPY wrapdocker.sh /usr/local/bin/wrapdocker
RUN chmod +x /usr/local/bin/wrapdocker

# See https://github.com/cruizba/ubuntu-dind/blob/master/startup.sh
COPY dockerd.conf /etc/supervisor/conf.d/
COPY logger.sh /opt/bash-utils/logger.sh

# place the jenkins slave startup script into the container
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh && rm -fr /sbin/initctl && ln -s /usr/local/bin/entrypoint.sh /sbin/initctl

# https://github.com/docker-library/docker/pull/166
#   dockerd-entrypoint.sh uses DOCKER_TLS_CERTDIR for auto-generating TLS certificates
#   dockerd-entrypoint.sh uses DOCKER_TLS_CERTDIR for auto-setting DOCKER_TLS_VERIFY and DOCKER_CERT_PATH
# (For this to work, at least the "client" subdirectory of this path needs to be shared between the client and server containers via a volume, "docker cp", or other means of data sharing.)
ENV DOCKER_TLS_CERTDIR=/certs
# also, ensure the directory pre-exists and has wide enough permissions for "dockerd-entrypoint.sh" to create subdirectories, even when run in "rootless" mode
RUN mkdir /certs /certs/client && chmod 1777 /certs /certs/client
# (doing both /certs and /certs/client so that if Docker does a "copy-up" into a volume defined on /certs/client, it will "do the right thing" by default in a way that still works for rootless users)

# drop back to the regular jenkins user - good practice
USER ubuntu
RUN mkdir ${HOME}/workspace && mkdir -p ${HOME}/.m2/repository

RUN helm plugin install https://github.com/chartmuseum/helm-push --version 0.9.0 && \
    helm plugin install https://github.com/technosophos/helm-gpg --version 0.1.0 && \
    helm plugin install https://github.com/databus23/helm-diff --version 3.1.3 && \
    helm plugin install https://github.com/ContainerSolutions/helm-monitor --version 0.4.0 && \
    helm plugin install https://github.com/ContainerSolutions/helm-convert --version 0.5.3 && \
    helm plugin install https://github.com/aslafy-z/helm-git --version 0.10.0 && \
    helm plugin install https://github.com/karuppiah7890/helm-schema-gen --version 0.0.4 && \
    helm plugin install https://github.com/datreeio/helm-datree

#ENV HELM_CUSTOM_REPO_URL=${HELM_CUSTOM_REPO_URL:-"https://registry-tmp.nabla.mobi/chartrepo/nabla"}
#RUN helm repo add custom ${HELM_CUSTOM_REPO_URL} --insecure-skip-tls-verify
# && mkdir ${HOME}/.helm
# Need to write on /home/jenkins/.config/helm/repositories.lock
RUN chmod -R 777 "${UBUNTU_USER_HOME}/.config/helm/" && ls -lrta ${UBUNTU_USER_HOME}/.config/helm/ || true
#RUN ls -lrta ${UBUNTU_USER_HOME}/.helm
RUN chmod -R 777 "${UBUNTU_USER_HOME}/.cache/helm/" && ls -lrta ${UBUNTU_USER_HOME}/.cache/helm/ || true

#RUN chmod g-w,o-w ${HOME} # Home directory on the server should not be writable by others
#WARNING below give access to all servers
# hadolint ignore=SC2015
RUN chmod 700 ${HOME}/.ssh && chmod 600 ${HOME}/.ssh/id_rsa* && chmod 644 ${HOME}/.ssh/authorized_keys ${HOME}/.ssh/known_hosts || true

#BELOW npm install is adding 700Mb to the images
#RUN npm install --only=production && npm run update-webdriver

# Will create $UBUNTU_USER_HOME/.local/share/applications/mimeapps.list
RUN google-chrome --version
#RUN chromium-browser --version
#RUN chown -R "${USER}:$(id -gn ${GROUP})" "$UBUNTU_USER_HOME/.local" && chmod -R 777 "${UBUNTU_USER_HOME}/.local"
#.config

# For github action
# checkov:skip=CKV_DOCKER_8:Ensure the last USER is not root
# hadolint ignore=DL3002
USER root
RUN mkdir /github && chown -R jenkins /github && chmod -R 777 /github

# Working dir
WORKDIR /tmp

VOLUME /var/lib/docker

EXPOSE 2375 2376

VOLUME ["/sys/fs/cgroup", "/tmp", "/run"]

ENTRYPOINT ["dockerd-entrypoint.sh"]
CMD ["/bin/bash"]

HEALTHCHECK NONE
#HEALTHCHECK CMD curl --fail http://localhost:8080/ || exit 1
