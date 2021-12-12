# syntax=docker/dockerfile:1.2.1

# This Dockerfile is used to build an image containing basic stuff to be used as a Jenkins slave build node.
# Multistage build is not possible with Jenkins Docker Pipeline Plugin
#FROM ubuntu:20.10
# See https://github.com/SeleniumHQ/docker-selenium/blob/3.141.59-zirconium/Base/Dockerfile
# focal
#FROM selenium/standalone-chrome:3.141.59-20210128 as selenium
FROM selenium/standalone-chrome:3.141.59-20210929 as selenium

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG JENKINS_USER_HOME=${JENKINS_USER_HOME:-/home/jenkins}
ENV http_proxy=${http_proxy:-""}
#ENV http_proxy=${http_proxy:-"http://127.0.0.1:3128"}
#ENV http_proxy=${http_proxy:-"http://10.21.185.171:3128"}
ENV https_proxy=${https_proxy:-"${http_proxy}"}
ENV no_proxy=${no_proxy:-"localhost,127.0.0.1,.albandrieu.com,.azure.io,albandri,albandrieu,10.199.52.11,.github.com,.docker.com,.ubuntu.com"}

# dockerfile_lint - ignore
LABEL name="ansible-jenkins-slave" version="2.0.0"
LABEL description="Image used by our products to build Java/Javascript and CPP\
 this image is running on Ubuntu 20.10."
LABEL com.example.vendor="ACME Incorporated"

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
RUN echo "APT::Acquire::Retries \"10\";" > /etc/apt/apt.conf.d/80-retries

# Configure apt to always assume Y
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

# Uninstall unattended-upgrades
#RUN apt-get purge unattended-upgrades

# Install ansible
# hadolint ignore=DL3008
RUN apt-get -q update &&\
    apt-get -q -o Dpkg::Options::="--force-confnew" --no-install-recommends install -y \
    git bzip2 zip unzip python-yaml python-jinja2 rsyslog gpg-agent \
    # python-pip
    ocl-icd-libopencl1 ocl-icd-opencl-dev clinfo numactl libnuma1 pciutils \
    apt-utils apt-transport-https ca-certificates software-properties-common \
    locales xz-utils ksh wget tzdata sudo curl lsof sshpass \
    systemd systemd-cron \
    python3-setuptools python3 python3-pip python3-dev python3-apt \
    python-lxml python3-lxml \
    openjdk-8-jdk openjdk-11-dbg maven gcc g++ make cmake \
    net-tools iputils-ping x11-apps libxss1 \
    gnome-keyring gnome-keyring gnupg2 pass \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Remove unnecessary getty and udev targets that result in high CPU usage when using
# multiple containers with Molecule (https://github.com/ansible/molecule/issues/1104)
RUN rm -f /lib/systemd/system/systemd*udev* \
  && rm -f /lib/systemd/system/getty.target

ENV TZ "Europe/Paris"
RUN echo "${TZ}" > /etc/timezone
RUN ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime && locale-gen en_US.UTF-8
#RUN dpkg-reconfigure --frontend noninteractive tzdata \

### PYTHON

RUN python3 -m pip install --proxy=${http_proxy} --upgrade pip==20.3.4 \
    && pip3 install --proxy=${http_proxy} ansible==4.6.0 ansible-core>=2.11.6 zabbix-api==0.5.4 docker-compose==1.25.5 sphinx==2.3.1 \
    && pip3 --version && python3 --version

### DOCKER

RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
RUN add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
# Install Docker from Docker Inc. repositories.
RUN apt-get update -qq && apt-get install --no-install-recommends -qqy docker-ce=5:20.10.3~3-0~ubuntu-focal docker-ce-cli=5:20.10.3~3-0~ubuntu-focal && apt-get clean && rm -rf /var/lib/apt/lists/*

### JAVASCRIPT

# hadolint ignore=DL3008,DL3015
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get update && apt-get install -y nodejs=14* && apt-get clean && rm -rf /var/lib/apt/lists/* && \
    npm set progress=false && \
    npm config set depth 0;
RUN npm install -g npm@6.14.15 && apt-get purge -y npm # && ln -s /usr/local/bin/npm /usr/bin/npm
RUN npm -v && command -v npm # 6.14.15
RUN npm install -g bower@1.8.12 grunt@1.4.1 grunt-cli@1.4.3 webdriver-manager@12.1.7 yarn@1.19.1 yo@latest shrinkwrap@0.4.0 json2csv@4.3.3 phantomas@1.20.1 dockerfile_lint@0.3.3 newman@5.2.2 newman-reporter-htmlextra@1.19.7 xunit-viewer@5.1.11 bower-nexus3-resolver@1.0.2

### USER

ARG USER=${USER:-jenkins}
ARG GROUP=${GROUP:-docker}
ARG UID=${UID:-2000}
ARG GID=${GID:-2000}
# hadolint ignore=SC2059
RUN printf "\033[1;32mFROM UID:GID: ${UID}:${GID}- JENKINS_USER_HOME: ${JENKINS_USER_HOME} \033[0m\n" && \
    printf "\033[1;32mWITH user: $USER\ngroup: $GROUP \033[0m\n"

#ENV DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${UID}/bus
RUN printenv DBUS_SESSION_BUS_ADDRESS

RUN groupmod -g ${GID} docker
#RUN cat /etc/group | grep docker || true
#RUN id docker
#RUN getent passwd 2000 || true

# Add user jenkins to the image
#RUN groupadd -g ${GID} docker && \
RUN adduser --quiet --uid ${UID} --gid ${GID} --home ${JENKINS_USER_HOME} jenkins
# Set password for the jenkins user (you may want to alter this).
RUN echo "jenkins:jenkins1234" | chpasswd
RUN usermod -a -G docker jenkins

# Add the jenkins user to sudoers
RUN echo "jenkins    ALL=(ALL)    ALL" >> /etc/sudoers

# hadolint ignore=SC2059
RUN curl -SsL https://github.com/boxboat/fixuid/releases/download/v0.4/fixuid-0.4-linux-amd64.tar.gz | tar -C /usr/local/bin -xzf - && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid && \
    printf "user: $USER\ngroup: $GROUP\n" > /etc/fixuid/config.yml

### ANSIBLE

# Install Ansible inventory file.
RUN mkdir -p /etc/ansible
RUN echo "[local]\nlocalhost ansible_connection=local" > /etc/ansible/hosts
ENV ANSIBLE_CONFIG=${JENKINS_USER_HOME}/ansible.cfg

ARG ANSIBLE_VAULT_PASS
ENV ANSIBLE_VAULT_PASS=${ANSIBLE_VAULT_PASS:-"microsoft"}
RUN echo "${ANSIBLE_VAULT_PASS}" > $JENKINS_USER_HOME/vault.passwd && cat $JENKINS_USER_HOME/vault.passwd
#COPY ansible.cfg $JENKINS_USER_HOME/
COPY *.yml $JENKINS_USER_HOME/
#COPY roles $JENKINS_USER_HOME/
COPY inventory $JENKINS_USER_HOME/inventory
COPY playbooks $JENKINS_USER_HOME/playbooks
RUN rm -Rf $JENKINS_USER_HOME/.ansible/roles/
COPY package.json $JENKINS_USER_HOME/
# hadolint ignore=SC2046
RUN chown jenkins:$(id -gn jenkins) $JENKINS_USER_HOME $JENKINS_USER_HOME/.*

# Execute
#python36,brew are adding 2.7 G to the images

# hadolint ignore=DL3008,DL3015
RUN ansible-galaxy install -r "$JENKINS_USER_HOME/requirements.yml" -p "$JENKINS_USER_HOME/.ansible/roles/" --ignore-errors && \
 ansible-playbook "$JENKINS_USER_HOME/playbooks/jenkins-slave-docker.yml" -i "$JENKINS_USER_HOME/inventory/hosts" -c local \
 -e "workspace=/tmp" \
 -e "jenkins_jdk8_enable=true" \
# -e "jenkins_ssh_key_file={{ jenkins_home }}/.ssh/id_rsa" \
# -e "jdk_home=/usr/lib/jvm/java-8-openjdk-amd64/" \
 -e "jenkins_id=${UID}" -e "docker_gid=${GID}" \
 -e "nis_enabled=false" -e "automount_enabled=false" -e "dns_enabled=false" \
 -e "python_enabled=false" \
 -e "ansible_python_interpreter=/usr/bin/python3.8" \
 --skip-tags=restart,vm,python35,python36,python37,brew,objc,kubernetes,nodejs \
 --vault-id $JENKINS_USER_HOME/vault.passwd \
 -vvvv \
 && apt-get autoremove -y && apt-get clean && apt-get remove asciidoc -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/man/* /var/log/* "$JENKINS_USER_HOME/roles" "$JENKINS_USER_HOME/playbooks" "$JENKINS_USER_HOME/inventory" "$JENKINS_USER_HOME/vault.passwd" "$JENKINS_USER_HOME/ansible.log" "$JENKINS_USER_HOME/requirements-*.txt" \
 && rm -Rf $JENKINS_USER_HOME/playbooks/.node_cache/ \
 && rm -Rf $JENKINS_USER_HOME/.cpan $JENKINS_USER_HOME/.ansible \
 && rm -Rf $JENKINS_USER_HOME/.npm $JENKINS_USER_HOME/.node_cache $JENKINS_USER_HOME/.cache/pip \
# && rm -Rf $JENKINS_USER_HOME/.local/share \
 && chown -R "jenkins:$(id -gn jenkins)" "$JENKINS_USER_HOME" && chmod -R 777 "${JENKINS_USER_HOME}"

#/usr/bin/python3.7 -m pip install --upgrade pip
RUN python3 -m pip install --proxy=${http_proxy} --upgrade pip==20.3.4 \
    && pip install --proxy=${http_proxy} ansible==4.6.0 ansible-core>=2.11.6 docker-compose==1.25.5 pre-commit==2.9.0 ansible-lint-junit==0.15 \
    && pip3 --version && python3 --version

# hadolint ignore=DL3008
RUN apt-get -q update && apt-get install --no-install-recommends -y curl \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN ifconfig | awk '/inet addr/{print substr($2,6)}' ## Display IP address (optional)

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
ENV DRAFT_VERSION v0.16.0
ENV DRAFT_FILENAME draft-${DRAFT_VERSION}-linux-amd64.tar.gz
ENV DRAFT_URL https://azuredraft.blob.core.windows.net/draft/${DRAFT_FILENAME}

# hadolint ignore=DL3020
#ADD ${DRAFT_URL} /tmp/${DRAFT_FILENAME}
RUN curl -L -o /tmp/${DRAFT_FILENAME} ${DRAFT_URL} \
  && tar -zxvf /tmp/${DRAFT_FILENAME} -C /tmp \
  && chmod +x /tmp/linux-amd64/draft \
  && mv /tmp/linux-amd64/draft /bin/draft \
  && draft init \
  && bash -c "echo \"y\" | draft pack-repo remove github.com/Azure/draft" \
  && rm -rf /tmp/* \
  && chmod -R 777 ${JENKINS_USER_HOME}/.draft && ls -lrta ${JENKINS_USER_HOME}/.draft/plugins/  # for .draft/plugins
# $JENKINS_USER_HOME/.draft/*

COPY wrapdocker /usr/local/bin/wrapdocker
RUN chmod +x /usr/local/bin/wrapdocker
#VOLUME /var/lib/docker

# place the jenkins slave startup script into the container
#ADD jenkins-slave-startup.sh /
COPY entrypoint.sh /
#RUN chmod +x /jenkins-slave-startup.sh /entrypoint.sh && rm -fr /sbin/initctl && ln -s /jenkins-slave-startup.sh /sbin/initctl
RUN chmod +x /entrypoint.sh && rm -fr /sbin/initctl && ln -s /entrypoint.sh /sbin/initctl

ARG AGENT_VERSION=${AGENT_VERSION:-"4.3"}
ARG AGENT_WORKDIR=${JENKINS_USER_HOME}/agent

RUN curl --create-dirs -fsSLo /usr/share/jenkins/agent.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${AGENT_VERSION}/remoting-${AGENT_VERSION}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/agent.jar \
  && ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar

COPY jenkins-agent.sh /usr/local/bin/jenkins-agent
RUN chmod +x /usr/local/bin/jenkins-agent && \
    ln -s /usr/local/bin/jenkins-agent /usr/local/bin/jenkins-slave

ENV AGENT_WORKDIR=${AGENT_WORKDIR}
RUN mkdir ${JENKINS_USER_HOME}/.jenkins && mkdir -p ${AGENT_WORKDIR}

ADD https://github.com/roboll/helmfile/releases/download/v0.138.2/helmfile_linux_amd64 /usr/local/bin/helmfile
#sudo cp helmfile_linux_amd64 /usr/local/bin/helmfile
RUN chmod +x /usr/local/bin/helmfile

ADD https://github.com/norwoodj/helm-docs/releases/download/v1.5.0/helm-docs_1.5.0_linux_amd64.deb /tmp/helm-docs_1.5.0_linux_amd64.deb
RUN dpkg -i /tmp/helm-docs_1.5.0_linux_amd64.deb && rm -rf /tmp/*

ADD https://github.com/instrumenta/kubeval/releases/latest/download/kubeval-linux-amd64.tar.gz /tmp/kubeval-linux-amd64.tar.gz
RUN tar xf /tmp/kubeval-linux-amd64.tar.gz && cp kubeval /usr/local/bin && rm -rf /tmp/*

# hadolint ignore=SC2046
RUN chown -R jenkins:$(id -gn jenkins) $HOME $HOME/.*

#RUN chmod go-r $HOME/.kube/config

ENV WEBDRIVER_CHROME_VERSION=${WEBDRIVER_CHROME_VERSION:-"70.0.3538.102"}
RUN webdriver-manager update --versions.chrome ${WEBDRIVER_CHROME_VERSION}

# drop back to the regular jenkins user - good practice
USER jenkins
RUN mkdir ${HOME}/workspace && mkdir -p ${HOME}/.m2/repository

RUN helm plugin install https://github.com/chartmuseum/helm-push --version 0.9.0 && \
    helm plugin install https://github.com/technosophos/helm-gpg --version 0.1.0 && \
    helm plugin install https://github.com/databus23/helm-diff --version 3.1.3 && \
    helm plugin install https://github.com/ContainerSolutions/helm-monitor --version 0.4.0 && \
    helm plugin install https://github.com/ContainerSolutions/helm-convert --version 0.5.3 && \
    helm plugin install https://github.com/aslafy-z/helm-git --version 0.10.0 && \
#    helm plugin install https://github.com/lrills/helm-unittest --version 0.1.5 && \
    helm plugin install https://github.com/karuppiah7890/helm-schema-gen --version 0.0.4

#ENV HELM_CUSTOM_REPO_URL=${HELM_CUSTOM_REPO_URL:-"https://registry-tmp.nabla.mobi/chartrepo/nabla"}
#RUN helm repo add custom ${HELM_CUSTOM_REPO_URL} --insecure-skip-tls-verify
# && mkdir ${HOME}/.helm
# Need to write on /home/jenkins/.config/helm/repositories.lock
RUN chmod -R 777 "${JENKINS_USER_HOME}/.config/helm/" && ls -lrta ${JENKINS_USER_HOME}/.config/helm/ || true
#RUN ls -lrta ${JENKINS_USER_HOME}/.helm
RUN chmod -R 777 "${JENKINS_USER_HOME}/.cache/helm/" && ls -lrta ${JENKINS_USER_HOME}/.cache/helm/ || true

#RUN chmod g-w,o-w ${HOME} # Home directory on the server should not be writable by others
#WARNING below give access to all servers
# hadolint ignore=SC2015
RUN chmod 700 ${HOME}/.ssh && chmod 600 ${HOME}/.ssh/id_rsa* && chmod 644 ${HOME}/.ssh/authorized_keys ${HOME}/.ssh/known_hosts || true

#BELOW npm install is adding 700Mb to the images
#RUN npm install --only=production && npm run update-webdriver

# Will create $JENKINS_USER_HOME/.local/share/applications/mimeapps.list
RUN google-chrome --version
#RUN chromium-browser --version
#RUN chown -R "jenkins:$(id -gn jenkins)" "$JENKINS_USER_HOME/.local" && chmod -R 777 "${JENKINS_USER_HOME}/.local"
#.config

# Working dir
#WORKDIR $JENKINS_USER_HOME
WORKDIR /tmp

EXPOSE 80

VOLUME ["/sys/fs/cgroup", "/tmp", "/run"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]

HEALTHCHECK NONE
#HEALTHCHECK CMD curl --fail http://localhost:8080/ || exit 1
