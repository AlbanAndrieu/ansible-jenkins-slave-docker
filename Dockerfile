# This Dockerfile is used to build an image containing basic stuff to be used as a Jenkins slave build node.
FROM ubuntu:16.04

MAINTAINER Alban Andrieu "https://github.com/AlbanAndrieu"

LABEL vendor="NABLA" version="1.0"
LABEL description="Image used by fusion-risk products to build Java/Javascript and CPP\
this image is running on Ubuntu 16.04."

ARG JENKINS_HOME=${JENKINS_HOME:-/home/jenkins}
ENV JENKINS_HOME=${JENKINS_HOME}

# Volume can be accessed outside of container
#VOLUME [${JENKINS_HOME}]

ENV DEBIAN_FRONTEND noninteractive
ENV WORKDIR /home/vagrant
ENV ANSIBLE_LIBRARY /tmp/ansible/library
ENV PYTHONPATH /tmp/ansible/lib:$PYTHON_PATH
ENV PATH /tmp/ansible/bin:/sbin:/usr/sbin:/usr/bin:/bin:$PATH

# Working dir
WORKDIR /tmp/ansible

ADD . $WORKDIR/

# Install ansible
ENV BUILD_PACKAGES="python-dev"
RUN apt-get clean && apt-get -y update && apt-get install -y $BUILD_PACKAGES git unzip python-yaml python-jinja2 python-pip ansible openssh-server rsyslog

# Add user jenkins to the image
#RUN adduser --quiet jenkins --home /home/jenkins
# Set password for the jenkins user (you may want to alter this).
#RUN echo jenkins:jenkins | chpasswd

# Execute
#RUN ansible --version
RUN echo localhost > hosts && ansible-playbook $WORKDIR/jenkins-slave.yml -i hosts -c local

# Install a basic SSH server
RUN mkdir -p /var/run/sshd

# Clean up APT when done.
ENV AUTO_ADDED_PACKAGES `apt-mark showauto`
RUN apt-get remove --purge -y $BUILD_PACKAGES $AUTO_ADDED_PACKAGES && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Standard SSH port
EXPOSE 22

#ENTRYPOINT  ["/etc/init.d/jenkins-swarm-client"]
CMD ["/usr/sbin/sshd", "-D"]
#CMD ["-g", "deamon off;"]
