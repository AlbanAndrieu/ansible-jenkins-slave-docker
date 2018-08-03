# This Dockerfile is used to build an image containing basic stuff to be used as a Jenkins slave build node.
# Multistage build is not possible with Jenkins Docker Pipeline Plugin
FROM selenium/standalone-chrome:3.12.0-cobalt

ARG FILEBEAT_VERSION=${FILEBEAT_VERSION:-6.3.0}
ARG JENKINS_HOME=${JENKINS_HOME:-/home/jenkins}
ARG UID=2000
ARG GID=2000

MAINTAINER Alban Andrieu "https://github.com/AlbanAndrieu"
LABEL vendor="NABLA" version="1.1"
LABEL description="Image used by Nabla products to build Java/Javascript and CPP\
 this image is running on Ubuntu 16.04."

# Volume can be accessed outside of container
#VOLUME [${JENKINS_HOME}]

# No interactive frontend during docker build
ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true

ENV JENKINS_HOME=${JENKINS_HOME} \
HOME=${JENKINS_HOME}

#ENV LANG en_US.UTF-8
ENV TERM="xterm-256color"

USER 0

RUN printf "\033[1;32mFROM FILEBEAT: ${FILEBEAT_VERSION} - JENKINS_HOME: ${JENKINS_HOME} \033[0m\n"

# Install ansible
ENV BUILD_PACKAGES="python-dev"
RUN apt-get clean && apt-get -y update && apt-get install -y \
    -o APT::Install-Recommend=false -o APT::Install-Suggests=false \
    $BUILD_PACKAGES git bzip2 zip unzip python-yaml python-jinja2 python-pip openssh-server rsyslog && pip install ansible==2.4.3.0 \
    && apt-get install -y ocl-icd-libopencl1 ocl-icd-opencl-dev clinfo numactl libnuma1 pciutils \
    xz-utils ksh wget tzdata sudo curl lsof sshpass \
    scons \
    python3 python3-pip python3-dev \
    openjdk-8-jdk maven \
    net-tools iputils-ping x11-apps

RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - ;\
    apt-get update && apt-get install -y nodejs ;\
    npm install -g bower grunt grunt-cli nsp

#====================
# Supervisor install
#====================
# TODO: Upgrade to supervisor stable 4.0 as soon as is released
# Check every now and then if version 4 is finally the stable one
#  https://pypi.python.org/pypi/supervisor
#  https://github.com/Supervisor/supervisor
# RUN apt -qqy update \
#   && apt -qqy install \
#     supervisor \
#ENV RUN_DIR="/var/run/sele"
#RUN SHA="ec495be4e28c694af1e41514e08c03cf6f1496c8" \
#  && pip install --no-cache \
#      "https://github.com/Supervisor/supervisor/zipball/${SHA}" || \
#     pip install --no-cache \
#      "https://github.com/Supervisor/supervisor/zipball/${SHA}" \
#  && rm -rf /var/lib/apt/lists/* \
#  && apt -qyy clean

# Add user jenkins to the image
RUN groupadd -g ${GID} docker && \
    adduser --quiet --uid ${UID} --gid ${GID} --home ${JENKINS_HOME} jenkins && \
    echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers
# Set password for the jenkins user (you may want to alter this).
RUN echo "jenkins:jenkins1234" | chpasswd

# Working dir
WORKDIR $JENKINS_HOME

#===================
# Timezone settings
# Possible alternative: https://github.com/docker/docker/issues/3359#issuecomment-32150214
#===================
ENV TZ "UTC"
RUN echo "${TZ}" > /etc/timezone \
  && dpkg-reconfigure --frontend noninteractive tzdata

#ADD . $JENKINS_HOME/
COPY *.yml package.json $JENKINS_HOME/
COPY roles $JENKINS_HOME/

#BELOW npm install is adding 700Mb to the images
#RUN npm install --only=production && npm run update-webdriver

# Execute
RUN ansible-galaxy install -r $JENKINS_HOME/requirements.yml -p $JENKINS_HOME/roles/ --ignore-errors \
 && ansible-playbook $JENKINS_HOME/jenkins-slave-docker.yml -i $JENKINS_HOME/hosts -c local
# -vvvv -e "jenkins_ssh_key_file={{ jenkins_home }}/.ssh/id_rsa" -e "workspace=/tmp"

#COPY . $JENKINS_HOME
#COPY --chown=jenkins:$(id -gn jenkins) . $JENKINS_HOME
#RUN chown -R jenkins:$(id -gn jenkins) $JENKINS_HOME

# Install a basic SSH server
RUN sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd
RUN mkdir -p /var/run/sshd
#RUN chmod 0755 /var/run/sshd

RUN curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${FILEBEAT_VERSION}-amd64.deb && sudo dpkg -i filebeat-${FILEBEAT_VERSION}-amd64.deb

# Clean up APT when done.
#RUN AUTO_ADDED_PACKAGES=$(apt-mark showauto) \
#&& apt-get remove --purge -y $BUILD_PACKAGES $AUTO_ADDED_PACKAGES &&
RUN apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
&& ifconfig | awk '/inet addr/{print substr($2,6)}' ## Display IP address (optional)

# drop back to the regular jenkins user - good practice
USER jenkins

# Standard SSH port
EXPOSE 22

#ENTRYPOINT ["/bin/bash"]
#CMD ["/usr/sbin/sshd", "-D"]
CMD ["/bin/bash"]
#CMD ["-g", "deamon off;"]
