#!/bin/bash
#set -xv

WORKING_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )"

# shellcheck source=/dev/null
source "${WORKING_DIR}/step-0-color.sh"
 
#readonly DOCKERREGISTRY="https://hub.docker.com/"
readonly DOCKERREGISTRY="" # leave it empty on purpose
readonly DOCKERORGANISATION="nabla"
readonly DOCKERUSERNAME=""
readonly DOCKERNAME="ansible-jenkins-slave-docker"
#readonly DOCKERTAG="ubuntu:16.04"
readonly DOCKERTAG="latest"

#source "${WORKING_DIR}/run-ansible.sh"

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
echo -e "${magenta} time docker build ${DOCKER_BUILD_ARGS} -f docker/ubuntu18/Dockerfile -t \"${DOCKERORGANISATION}/${DOCKERNAME}\" . --tag \"${DOCKERTAG}\" ${NC}"
time docker build ${DOCKER_BUILD_ARGS} -f docker/ubuntu18/Dockerfile -t "${DOCKERORGANISATION}/${DOCKERNAME}" . --tag "${DOCKERTAG}"
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
echo -e "    docker login ${DOCKERREGISTRY} --username ${DOCKERUSERNAME} --password password"
echo -e "    docker tag ${DOCKERORGANISATION}/${DOCKERNAME}:latest ${DOCKERREGISTRY}${DOCKERORGANISATION}/${DOCKERNAME}:${DOCKERTAG}"
echo -e "    docker push ${DOCKERREGISTRY}${DOCKERORGANISATION}/${DOCKERNAME}"
echo -e ""
echo -e "To pull it"
echo -e "    docker pull ${DOCKERREGISTRY}${DOCKERORGANISATION}/${DOCKERNAME}:${DOCKERTAG}"
echo -e ""
echo -e "To use this docker:"
echo -e "    docker run -d -P ${DOCKERORGANISATION}/${DOCKERNAME}"
echo -e " - to attach your container directly to the host's network interfaces"
echo -e "    docker run --net host -d -P ${DOCKERORGANISATION}/${DOCKERNAME}"
echo -e ""
echo -e "To run in interactive mode for debug:"
echo -e "    docker run -i -t --entrypoint /bin/bash ${DOCKERORGANISATION}/${DOCKERNAME}:latest"
echo -e "    docker run -it -d --name sandbox ${DOCKERORGANISATION}/${DOCKERNAME}:latest"
echo -e "    docker exec -it sandbox /bin/bash"
echo -e "    docker exec -u 0 -it sandbox env TERM=xterm-256color bash -l"
echo -e ""

exit 0
