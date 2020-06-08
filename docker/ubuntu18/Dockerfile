# This Dockerfile is used to build an image containing basic stuff to be used as a Jenkins slave build node.
# Multistage build is not possible with Jenkins Docker Pipeline Plugin
#FROM selenium/standalone-chrome:3.141.59-yttrium
#FROM selenium/standalone-chrome:3.141.59-zirconium
#FROM selenium/standalone-chrome:3.141.59-20200409
FROM ubuntu:18.04

ARG JENKINS_USER_HOME=${JENKINS_USER_HOME:-/home/jenkins}

# dockerfile_lint - ignore
MAINTAINER Alban Andrieu "https://github.com/AlbanAndrieu"
LABEL Name="ansible-jenkins-slave-docker" Version="1.0.2"
LABEL description="Image used by Nabla products to build Java/Javascript and CPP\
 this image is running on Ubuntu 18.04."
LABEL com.example.vendor="ACME Incorporated"

# In case you need proxy
#RUN echo 'Acquire::http::Proxy "http://127.0.0.1:8080";' >> /etc/apt/apt.conf

# No interactive frontend during docker build
ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true

#Below HOME is needed to override seluser (selenium user)
ENV HOME=${JENKINS_USER_HOME}

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV TERM="xterm-256color"

USER root

# Install ansible
# hadolint ignore=DL3008
RUN apt-get -q update &&\
#    apt-get -q upgrade -y -o Dpkg::Options::="--force-confnew" --no-install-recommends &&\
    apt-get -q install -y -o Dpkg::Options::="--force-confnew" --no-install-recommends \
    git bzip2 zip unzip python-yaml python-jinja2 python-pip rsyslog gpg-agent \
    ocl-icd-libopencl1 ocl-icd-opencl-dev clinfo numactl libnuma1 pciutils \
    apt-utils apt-transport-https ca-certificates software-properties-common \
    locales xz-utils ksh wget tzdata sudo curl lsof sshpass \
    systemd systemd-cron \
    python3-setuptools python3 python3-pip python3-dev python3-apt \
    openjdk-8-jdk maven gcc g++ make \
    net-tools iputils-ping x11-apps \
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

# error with pip==19.3.1
# error with ansible==2.9.1 and (2.8.6 and 2.8.8) (buggy https://github.com/ansible/ansible/issues/13763), ok with 2.7.14 and ok with 20.0.2 on ubuntu 18 with python 3.6 and 19 with python 3.7
RUN python3 -m pip install --upgrade pip==20.0.2 \
    && pip3 install ansible==2.7.14 zabbix-api==0.5.4 docker-compose==1.25.3

RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
RUN add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
# Install Docker from Docker Inc. repositories.
RUN apt-get update -qq && apt-get install -qqy docker-ce=5:19.03.4~3-0~ubuntu-bionic docker-ce-cli=5:19.03.8~3-0~ubuntu-bionic && apt-get clean && rm -rf /var/lib/apt/lists/*

# hadolint ignore=DL3008,DL3015
# See issue https://askubuntu.com/questions/1036278/npm-is-incorrect-version-on-latest-ubuntu-18-04-installation
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
    apt-get update && apt-get install -y nodejs=8.10.0~dfsg-2ubuntu0.4 npm=3.5.2-0ubuntu4 && apt-get clean && rm -rf /var/lib/apt/lists/* && \
    npm set progress=false && \
    npm config set depth 0;
RUN npm install -g npm && apt purge -y npm && ln -s /usr/local/bin/npm /usr/bin/npm
RUN npm -v && command -v npm # 6.7.0
RUN npm install -g bower@1.8.8 grunt@1.0.4 grunt-cli@1.3.2 webdriver-manager@12.1.7 yarn@1.19.1 yo@3.1.1
#RUN npm install -g shrinkwrap@0.4.0 newman@4.5.5 xunit-viewer@5.1.11 json2csv@4.3.3 phantomas@1.20.1 dockerfile_lint@0.3.3q
RUN npm install -g npm@6.14.4

ARG USER=${USER:-jenkins}
ARG GROUP=${GROUP:-docker}
ARG UID=${UID:-2000}
ARG GID=${GID:-2000}
RUN printf "\033[1;32mFROM UID:GID: ${UID}:${GID}- JENKINS_USER_HOME: ${JENKINS_USER_HOME} \033[0m\n" && \
    printf "\033[1;32mWITH user: $USER\ngroup: $GROUP \033[0m\n"

#ENV DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${UID}/bus
#RUN export DBUS_SESSION_BUS_ADDRESS=`dbus-daemon --session --fork --print-address`
#ENV DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS}
RUN printenv DBUS_SESSION_BUS_ADDRESS || true

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

RUN curl -SsL https://github.com/boxboat/fixuid/releases/download/v0.4/fixuid-0.4-linux-amd64.tar.gz | tar -C /usr/local/bin -xzf - && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid && \
    printf "user: $USER\ngroup: $GROUP\n" > /etc/fixuid/config.yml

# Install Ansible inventory file.
RUN mkdir -p /etc/ansible
RUN echo "[local]\nlocalhost ansible_connection=local" > /etc/ansible/hosts
ENV ANSIBLE_CONFIG=${JENKINS_USER_HOME}/ansible.cfg

ARG ANSIBLE_VAULT_PASS
ENV ANSIBLE_VAULT_PASS=${ANSIBLE_VAULT_PASS:-"microsoft"}
#RUN echo "ANSIBLE_VAULT_PASS : ${ANSIBLE_VAULT_PASS}"
RUN echo "${ANSIBLE_VAULT_PASS}" > $JENKINS_USER_HOME/vault.passwd && cat $JENKINS_USER_HOME/vault.passwd
#COPY vault.passwd $JENKINS_USER_HOME/vault.passwd
#COPY ansible.cfg
COPY *.yml $JENKINS_USER_HOME/
#COPY roles $JENKINS_USER_HOME/
COPY inventory $JENKINS_USER_HOME/inventory
COPY playbooks $JENKINS_USER_HOME/playbooks
#COPY roles $JENKINS_USER_HOME/.ansible/roles
RUN rm -Rf $JENKINS_USER_HOME/.ansible/roles/
#RUN rm -f $JENKINS_USER_HOME/.ansible/roles/alban.andrieu.jenkins-slave $JENKINS_USER_HOME/.ansible/roles/alban.andrieu.workstation $JENKINS_USER_HOME/.ansible/roles/alban.andrieu.cpp $JENKINS_USER_HOME/.ansible/roles/alban.andrieu.gcc $JENKINS_USER_HOME/.ansible/roles/chrome
#RUN ls -lrta $JENKINS_USER_HOME/.ansible/roles | true
#RUN ls -lrta $JENKINS_USER_HOME/roles | true
#COPY .ssh $JENKINS_USER_HOME/.ssh
COPY package.json $JENKINS_USER_HOME/
#RUN id jenkins && ls -lrta $JENKINS_USER_HOME/
RUN chown jenkins:$(id -gn jenkins) $JENKINS_USER_HOME $JENKINS_USER_HOME/.*

# Execute
RUN ansible-galaxy install -r "$JENKINS_USER_HOME/requirements.yml" -p "$JENKINS_USER_HOME/.ansible/roles/" --ignore-errors && \
 ansible-playbook "$JENKINS_USER_HOME/playbooks/jenkins-slave-docker.yml" -i "$JENKINS_USER_HOME/inventory/hosts" -c local \
 -e "workspace=/tmp" \
 -e "jenkins_jdk8_enable=true" \
# -e "jenkins_ssh_key_file={{ jenkins_home }}/.ssh/id_rsa" \
# -e "jdk_home=/usr/lib/jvm/java-8-openjdk-amd64/" \
 -e "jenkins_id=${UID}" -e "docker_gid=${GID}" \
 -e "nis_enabled=false" -e "automount_enabled=false" -e "dns_enabled=false" \
 --skip-tags=restart,vm,python35,python36,objc \
 --vault-id $JENKINS_USER_HOME/vault.passwd \
 -vvvv \
 && apt-get autoremove -y && apt-get clean && apt-get remove asciidoc -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/man/* /var/log/* "$JENKINS_USER_HOME/roles" "$JENKINS_USER_HOME/vault.passwd" "$JENKINS_USER_HOME/ansible.log" \
 && chown -R "jenkins:$(id -gn jenkins)" "$JENKINS_USER_HOME" && chmod -R 777 "${JENKINS_USER_HOME}"

RUN apt-get update && apt-get install -qqy curl

RUN which hadolint || true

RUN ifconfig | awk '/inet addr/{print substr($2,6)}' ## Display IP address (optional)

ENV HELM_VERSION v3.2.1
ENV HELM_FILENAME helm-${HELM_VERSION}-linux-amd64.tar.gz
#ENV HELM_URL https://storage.googleapis.com/kubernetes-helm/${HELM_FILENAME}
ENV HELM_URL https://get.helm.sh/${HELM_FILENAME}

#curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# Kubernetes tools
ADD ${HELM_URL} /tmp/${HELM_FILENAME}
RUN tar -zxvf /tmp/${HELM_FILENAME} -C /tmp \
  && chmod +x /tmp/linux-amd64/helm \
  && mv /tmp/linux-amd64/helm /bin/helm \
  && rm -rf /tmp/*

ENV KUBECTL_VERSION v1.18.3
ENV KUBECTL_URL https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl

ADD ${KUBECTL_URL} /tmp/kubectl
RUN chmod +x /tmp/kubectl \
  && mv /tmp/kubectl /bin/kubectl \
  && rm -rf /tmp/*

ADD https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64 skaffold
RUN chmod +x skaffold && mv skaffold /usr/local/bin
RUN skaffold version

ENV DRAFT_VERSION v0.16.0
ENV DRAFT_FILENAME draft-${DRAFT_VERSION}-linux-amd64.tar.gz
ENV DRAFT_URL https://azuredraft.blob.core.windows.net/draft/${DRAFT_FILENAME}

RUN echo DRAFT_URL : ${DRAFT_URL}

ADD ${DRAFT_URL} /tmp/${DRAFT_FILENAME}
RUN tar -zxvf /tmp/${DRAFT_FILENAME} -C /tmp \
  && chmod +x /tmp/linux-amd64/draft \
  && mv /tmp/linux-amd64/draft /bin/draft

RUN draft init && \
    bash -c "echo \"y\" | draft pack-repo remove github.com/Azure/draft"

ADD https://get.aquasec.com/microscanner /
RUN chmod +x /microscanner

ADD wrapdocker /usr/local/bin/wrapdocker
RUN chmod +x /usr/local/bin/wrapdocker
#VOLUME /var/lib/docker

# place the jenkins slave startup script into the container
#ADD jenkins-slave-startup.sh /
ADD entrypoint.sh /
#RUN chmod +x /jenkins-slave-startup.sh /entrypoint.sh && rm -fr /sbin/initctl && ln -s /jenkins-slave-startup.sh /sbin/initctl
RUN chmod +x /entrypoint.sh && rm -fr /sbin/initctl && ln -s /entrypoint.sh /sbin/initctl

# See https://github.com/jenkinsci/docker-agent
ARG VERSION=4.3
ARG AGENT_WORKDIR=${JENKINS_USER_HOME}/agent

RUN curl --create-dirs -fsSLo /usr/share/jenkins/agent.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/agent.jar \
  && ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar

COPY jenkins-agent.sh /usr/local/bin/jenkins-agent
RUN chmod +x /usr/local/bin/jenkins-agent && \
    ln -s /usr/local/bin/jenkins-agent /usr/local/bin/jenkins-slave

ENV AGENT_WORKDIR=${AGENT_WORKDIR}
RUN mkdir ${JENKINS_USER_HOME}/.jenkins && mkdir -p ${AGENT_WORKDIR}

RUN ls -lrta /tmp && chmod -R 777 /tmp

# drop back to the regular jenkins user - good practice
USER jenkins
RUN mkdir ${JENKINS_USER_HOME}/workspace && mkdir -p ${JENKINS_USER_HOME}/.m2/repository && chmod 777 ${JENKINS_USER_HOME}/ansible.log || true && chmod -R 777 ${JENKINS_USER_HOME}/.cache

#RUN helm init --client-only
#RUN helm plugin install https://github.com/chartmuseum/helm-push.git

#RUN chmod g-w,o-w ${HOME} # Home directory on the server should not be writable by others
#WARNING below give access to all servers
RUN chmod 700 ${HOME}/.ssh && chmod 600 ${HOME}/.ssh/id_rsa* && chmod 644 ${HOME}/.ssh/authorized_keys ${HOME}/.ssh/known_hosts || true

#RUN id jenkins && mkdir ${JENKINS_USER_HOME}/.local && ls -lrtai $JENKINS_USER_HOME/ && ls -lrtai $JENKINS_USER_HOME/.sonar

#BELOW npm install is adding 700Mb to the images
#RUN npm install --only=production && npm run update-webdriver

#RUN /microscanner ${MICROSCANNER_TOKEN} --continue-on-failure 2>&1 > ${HOME}/microscanner.log
#RUN echo "No vulnerabilities!"
#RUN /microscanner ${token} && rm /microscanner

RUN rm -f /home/jenkins/alban.andrieu.conky/files/default-themes-extra-1.tar.gz || true

# Working dir
WORKDIR $JENKINS_USER_HOME

EXPOSE 80

VOLUME ["/sys/fs/cgroup", "/tmp", "/run"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
#CMD ["/usr/lib/systemd/systemd"]
