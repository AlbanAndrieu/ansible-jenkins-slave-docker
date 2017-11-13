#!/bin/bash

DOCKERNAME="nabla/ansible-jenkins-slave-docker"

time docker build -f Dockerfile-jenkins-slave-ubuntu:16.04 -t $DOCKERNAME . --no-cache --tag "ubuntu:16.04"

echo
echo "This image is a trusted docker hub Image."
echo "See https://hub.docker.com/r/nabla/ansible-jenkins-slave-docker/"
echo
echo "To pull it"
echo "    docker pull $DOCKERNAME"
echo
echo "To use this docker:"
echo "    docker run -d -P $DOCKERNAME"
echo " - to attach your container directly to the host's network interfaces"
echo "    docker run --net host -d -P $DOCKERNAME"
echo
echo "To run in interactive mode for debug:"
echo "    docker run -t -i $DOCKERNAME bash"
echo

exit 0
