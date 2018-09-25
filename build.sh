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
#export DOCKERREGISTRY="https://hub.docker.com/"
export DOCKERORGANISATION="nabla"
export DOCKERUSERNAME=""
export DOCKERNAME="ansible-jenkins-slave-docker"
#export DOCKERTAG="ubuntu:16.04"
export DOCKERTAG="latest"

#source ./playbooks/run-ansible.sh

echo -e "${green} Insalling roles version ${NC}"
ansible-galaxy install -r requirements.yml -p ./roles/ --ignore-errors

if [ -n "${DOCKER_BUILD_ARGS}" ]; then
  echo -e "${green} DOCKER_BUILD_ARGS is defined ${happy_smiley} : ${DOCKER_BUILD_ARGS} ${NC}"
else
  echo -e "${red} ${double_arrow} Undefined build parameter ${head_skull} : DOCKER_BUILD_ARGS, use the default one ${NC}"
  export DOCKER_BUILD_ARGS="--pull"
  #export DOCKER_BUILD_ARGS="--build-arg --no-cache"
  echo -e "${magenta} DOCKER_BUILD_ARGS : ${DOCKER_BUILD_ARGS} ${NC}"
fi

echo -e "${green} Building docker image ${NC}"
echo -e "${magenta} time docker build ${DOCKER_BUILD_ARGS} -f docker/ubuntu16/Dockerfile -t \"$DOCKERORGANISATION/$DOCKERNAME\" . --tag \"$DOCKERTAG\" ${NC}"
time docker build "${DOCKER_BUILD_ARGS}" -f docker/ubuntu16/Dockerfile -t "${DOCKERORGANISATION}/${DOCKERNAME}" . --tag "$DOCKERTAG"
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
echo -e "    docker tag $DOCKERREGISTRY/$DOCKERORGANISATION/$DOCKERNAME:$DOCKERTAG $DOCKERREGISTRY/$DOCKERORGANISATION/$DOCKERNAME:$DOCKERTAG"
echo -e "    docker push $DOCKERREGISTRY/$DOCKERORGANISATION/$DOCKERNAME"
echo -e ""
echo -e "To pull it"
echo -e "    docker pull $DOCKERREGISTRY/$DOCKERORGANISATION/$DOCKERNAME:$DOCKERTAG"
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
