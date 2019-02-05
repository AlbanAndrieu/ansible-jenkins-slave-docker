# This Dockerfile is used to build an image containing basic stuff to be used as a Jenkins slave build node.
# Multistage build is not possible with Jenkins Docker Pipeline Plugin
FROM selenium/standalone-chrome:3.141.59-antimony

ARG JENKINS_HOME=${JENKINS_HOME:-/home/jenkins}

MAINTAINER Alban Andrieu "https://github.com/AlbanAndrieu"
LABEL vendor="NABLA" version="1.1"
LABEL description="Image used by Nabla products to build Java/Javascript and CPP\
 this image is running on Ubuntu 16.04."

# In case you need proxy
#RUN echo 'Acquire::http::Proxy "http://127.0.0.1:8080";' >> /etc/apt/apt.conf

# Volume can be accessed outside of container
#VOLUME [${JENKINS_HOME}]

# No interactive frontend during docker build
#ENV DEBIAN_FRONTEND=noninteractive \
#    DEBCONF_NONINTERACTIVE_SEEN=true

ENV JENKINS_HOME=${JENKINS_HOME}

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV TERM="xterm-256color"

USER 0

# Install ansible
RUN locale-gen $LANG &&\
    apt-get -q update &&\
    apt-get -q upgrade -y -o Dpkg::Options::="--force-confnew" --no-install-recommends &&\
    apt-get -q install -y -o Dpkg::Options::="--force-confnew" --no-install-recommends \
    git bzip2 zip unzip python-yaml python-jinja2 python-pip openssh-server rsyslog && pip install ansible==2.7.2 \
    && apt-get install -y ocl-icd-libopencl1 ocl-icd-opencl-dev clinfo numactl libnuma1 pciutils \
    apt-transport-https ca-certificates software-properties-common \
    xz-utils ksh wget tzdata sudo curl lsof sshpass \
    scons \
    python3-setuptools python3 python3-pip python3-dev python3-apt \
    openjdk-8-jdk maven gcc g++ make \
    net-tools iputils-ping x11-apps \
    && pip install zabbix-api

RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
RUN add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
# Install Docker from Docker Inc. repositories.
RUN apt-get update -qq && apt-get install -qqy docker-ce=5:18.09.0~3-0~ubuntu-xenial && rm -rf /var/lib/apt/lists/*

RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - ;\
    apt-get update && apt-get install -y nodejs ;\
    npm install -g bower@1.8.4 grunt@1.0.3 grunt-cli@1.3.2 nsp@3.2.1 webdriver-manager@12.1.0 npm@6.4.1 yo@2.0.5

ARG UID=${UID:-2000}
ARG GID=${GID:-2000}
RUN printf "\033[1;32mFROM UID:GID: ${UID}:${GID}- JENKINS_HOME: ${JENKINS_HOME} \033[0m\n"

RUN groupmod -g ${GID} docker

# Add user jenkins to the image
#RUN groupadd -g ${GID} docker && \
RUN adduser --quiet --uid ${UID} --gid ${GID} --home ${JENKINS_HOME} jenkins && \
    echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers
# Set password for the jenkins user (you may want to alter this).
RUN echo "jenkins:jenkins1234" | chpasswd
RUN usermod -a -G docker jenkins

# Working dir
#WORKDIR $JENKINS_HOME

#===================
# Timezone settings
# Possible alternative: https://github.com/docker/docker/issues/3359#issuecomment-32150214
#===================
ENV TZ "UTC"
RUN echo "${TZ}" > /etc/timezone \
  && dpkg-reconfigure --frontend noninteractive tzdata

#package.json group_vars .ssh ansible.pub.key
COPY *.yml playbooks hosts roles $JENKINS_HOME/
RUN chown -R jenkins:$(id -gn jenkins) $JENKINS_HOME $JENKINS_HOME/.*

#BELOW npm install is adding 700Mb to the images
#RUN npm install --only=production && npm run update-webdriver

# Execute
RUN ansible-galaxy install -r $JENKINS_HOME/requirements.yml -p $JENKINS_HOME/roles/ --ignore-errors \
 && ansible-playbook $JENKINS_HOME/jenkins-slave-docker.yml -i $JENKINS_HOME/hosts -c local \
# -e "jenkins_ssh_key_file={{ jenkins_home }}/.ssh/id_rsa"
 -e "workspace=/tmp" \
 -e "jenkins_jdk8_enable=true" -e "jdk_home=/usr/lib/jvm/java-8-oracle/" \
 -e "jenkins_id=${UID}" -e "docker_gid=${GID}" \
 -e "nis_enabled=false" -e "automount_enabled=false" -e "dns_enabled=false" \
 --skip-tags restart \
# --vault-id $JENKINS_HOME/vault.passwd \
 -vvvv

#COPY . $JENKINS_HOME
#COPY --chown=jenkins:$(id -gn jenkins) . $JENKINS_HOME
RUN chown -R jenkins:$(id -gn jenkins) $JENKINS_HOME

# Install a basic SSH server
RUN sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd
RUN mkdir -p /var/run/sshd
#RUN chmod 0755 /var/run/sshd

# Clean up APT when done.
RUN apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
&& ifconfig | awk '/inet addr/{print substr($2,6)}' ## Display IP address (optional)

# drop back to the regular jenkins user - good practice
USER jenkins
ENV HOME=${JENKINS_HOME}
RUN chmod -R 777 ${HOME} && mkdir ${HOME}/workspace && mkdir ${HOME}/.config && mkdir ${HOME}/.local && mkdir ${HOME}/.sonar
#RUN id jenkins && ls -lrtai $HOME/ && ls -lrtai $HOME/.sonar

# Standard SSH port
EXPOSE 22

#ENTRYPOINT ["/bin/bash"]
#CMD ["/usr/sbin/sshd", "-D"]
CMD ["/bin/bash"]
#CMD ["-g", "deamon off;"]
