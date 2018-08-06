#!/bin/bash
#set -xv

#export bold="\033[01m"
#export underline="\033[04m"
#export blink="\033[05m"

#export black="\033[30m"
export red="\033[31m"
export green="\033[32m"
#export yellow="\033[33m"
#export blue="\033[34m"
#export magenta="\033[35m"
#export cyan="\033[36m"
#export ltgray="\033[37m"

export NC="\033[0m"

#export double_arrow='\xC2\xBB'
export head_skull='\xE2\x98\xA0'
export happy_smiley='\xE2\x98\xBA'
# shellcheck disable=SC2034
export reverse_exclamation='\u00A1'
#export DOCKERREGISTRY=""
#export DOCKERORGANISATION=""
export DOCKERUSERNAME="nabla"
export DOCKERNAME="ansible-jenkins-slave-docker"
#export DOCKERTAG="ubuntu:16.04"
export DOCKERTAG="latest"

#source ./playbooks/run-ansible.sh

echo -e "${green} Insalling roles version ${NC}"
ansible-galaxy install -r requirements.yml -p ./roles/ --ignore-errors

echo -e "${green} Building docker image ${NC}"
echo -e "${magenta} time docker build -f docker/ubuntu16/Dockerfile -t \"$DOCKERUSERNAME/$DOCKERNAME\" . --no-cache --tag \"$DOCKERTAG\" ${NC}"
time docker build -f docker/ubuntu16/Dockerfile -t "$DOCKERUSERNAME/$DOCKERNAME" . --no-cache --tag "$DOCKERTAG"
RC=$?
if [ ${RC} -ne 0 ]; then
  echo ""
  echo -e "${red} ${head_skull} Sorry, build failed. ${NC}"
  exit 1
else
  echo -e "${green} The build completed successfully. ${NC}"
fi

echo -e ""
echo -e "${green} This image is a trusted docker hub Image. ${happy_smiley} ${NC}"
echo -e "See https://hub.docker.com/r/nabla/ansible-jenkins-slave-docker/"
echo -e ""
echo -e "To push it"
echo -e "    docker login ${DOCKERREGISTRY} --username $DOCKERUSERNAME --password password"
echo -e "    docker tag $DOCKERUSERNAME/$DOCKERNAME:$DOCKERTAG $DOCKERUSERNAME/$DOCKERNAME:$DOCKERTAG"
echo -e "    docker push $DOCKERUSERNAME/$DOCKERNAME:$DOCKERTAG"
echo -e ""
echo -e "To pull it"
echo -e "    docker pull $DOCKERUSERNAME/$DOCKERNAME/$DOCKERNAME:$DOCKERTAG"
echo -e ""
echo -e "To use this docker:"
echo -e "    docker run -d -P $DOCKERUSERNAME/$DOCKERNAME"
echo -e " - to attach your container directly to the host's network interfaces"
echo -e "    docker run --net host -d -P $DOCKERUSERNAME/$DOCKERNAME"
echo -e ""
echo -e "To run in interactive mode for debug:"
echo -e "    docker run -t -i $DOCKERUSERNAME/$DOCKERNAME bash"
echo -e ""

exit 0
