# This file was generated by ansible for albandri-laptop-misys.misys.global.ad
# This Dockerfile is used to build an image containing basic stuff to be used as a Jenkins slave build node.
#FROM        ubuntu:latest
FROM        ubuntu:14.04

# Volume can be accessed outside of container
VOLUME      [/home/jenkins]

MAINTAINER  Alban Andrieu "https://github.com/AlbanAndrieu"

ENV			DEBIAN_FRONTEND noninteractive
ENV         JENKINS_HOME /home/jenkins
ENV         WORKDIR /home/vagrant
ENV         ANSIBLE_LIBRARY /tmp/ansible/library
ENV         PYTHONPATH /tmp/ansible/lib:$PYTHON_PATH
ENV         PATH /tmp/ansible/bin:/sbin:/usr/sbin:/usr/bin:/bin:$PATH

# Working dir
WORKDIR /tmp/ansible

# Because docker replaces /sbin/init: https://github.com/dotcloud/docker/issues/1024 
RUN dpkg-divert --local --rename --add /sbin/initctl

# Make sure the package repository is up to date.
#RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
#RUN echo "deb http://archive.ubuntu.com/ubuntu trusty main universe" > /etc/apt/sources.list
RUN apt-get clean && apt-get -y update

# COPY
#COPY /workspace/users/albandri10/env/ansible/roles/jenkins-slave $WORKDIR

#RUN git pull && git submodule init && git submodule update && git submodule status
#RUN git submodule foreach git checkout master

ADD roles $WORKDIR/roles

RUN ls -lrta $WORKDIR/roles/*

#ADD defaults $WORKDIR/ansible-jenkins-slave/defaults
#ADD meta $WORKDIR/ansible-jenkins-slave/meta
#ADD files $WORKDIR/ansible-jenkins-slave/files
##ADD handlers $WORKDIR/ansible-jenkins-slave/handlers
#ADD tasks $WORKDIR/ansible-jenkins-slave/tasks
#ADD templates $WORKDIR/ansible-jenkins-slave/templates
#ADD vars $WORKDIR/ansible-jenkins-slave/vars

# Here we continue to use add because
# there are a limited number of RUNs
# allowed.
ADD hosts /etc/ansible/hosts
ADD jenkins-slave-docker.yml $WORKDIR/jenkins-slave.yml

# Install ansible
RUN apt-get install -y python-dev python-yaml python-jinja2 git unzip python-pip
RUN pip install paramiko PyYAML jinja2 httplib2 boto && pip install ansible
#RUN git clone http://github.com/ansible/ansible.git /tmp/ansible
#RUN mkdir /tmp/ansible 

# Install JDK 7 (latest edition)
#RUN apt-get install -y --no-install-recommends openjdk-7-jdk

# Add user jenkins to the image
#RUN         adduser --quiet jenkins --home /home/jenkins
# Set password for the jenkins user (you may want to alter this).
#RUN         echo jenkins:jenkins | chpasswd

# Execute
RUN         ansible-playbook $WORKDIR/jenkins-slave.yml -c local

# Install a basic SSH server
RUN apt-get install -y openssh-server
RUN mkdir -p /var/run/sshd
#RUN         apt-get update && \
#            apt-get install -y openssh-server openjdk-7-jre-headless

# Standard SSH port
EXPOSE      22
# Standard MySQL port for Sonar
#EXPOSE      3306

#ENTRYPOINT  ["/etc/init.d/jenkins-swarm-client"]
CMD ["/usr/sbin/sshd", "-D"]
#CMD ["-g", "deamon off;"]
