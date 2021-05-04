#!/bin/bash
#set -xv
shopt -s extglob

#set -ueo pipefail
set -eo pipefail

WORKING_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )"

export DOCKER_TAG="1.0.16"

if [ -n "${DOCKER_BUILD_ARGS}" ]; then
  echo -e "${green} DOCKER_BUILD_ARGS is defined ${happy_smiley} : ${DOCKER_BUILD_ARGS} ${NC}"
else
  echo -e "${red} ${double_arrow} Undefined build parameter ${head_skull} : DOCKER_BUILD_ARGS, use the default one ${NC}"
  export DOCKER_BUILD_ARGS="--pull --build-arg ANSIBLE_VAULT_PASS=${ANSIBLE_VAULT_PASS} "
  #export DOCKER_BUILD_ARGS="--build-arg --no-cache"
  echo -e "${magenta} DOCKER_BUILD_ARGS : ${DOCKER_BUILD_ARGS} ${NC}"
fi

# shellcheck source=/dev/null
source "${WORKING_DIR}/docker-env.sh"

#export DOCKER_NAME=${DOCKER_NAME:-"ansible-jenkins-slave-docker"}
export DOCKER_FILE="../docker/ubuntu18/Dockerfile"

echo -e "${green} Validating Docker ${NC}"
echo -e "${magenta} hadolint ${WORKING_DIR}/${DOCKER_FILE} ${NC}"
hadolint "${WORKING_DIR}/${DOCKER_FILE}" || true | tee -a docker-hadolint.log
echo -e "${magenta} dockerfile_lint --json --verbose --dockerfile ${WORKING_DIR}/${DOCKER_FILE} ${NC}"
dockerfile_lint --json --verbose --dockerfile "${WORKING_DIR}/${DOCKER_FILE}"|| true | tee -a docker-dockerfilelint.log

# shellcheck source=/dev/null
source "${WORKING_DIR}/run-ansible.sh"

WORKING_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )"

"${WORKING_DIR}/../clean.sh"

echo -e "${green} Installing roles version ${NC}"
${ANSIBLE_GALAXY_CMD} install -r requirements.yml -p ./roles/ --ignore-errors

if [ -n "${DOCKER_BUILD_ARGS}" ]; then
  echo -e "${green} DOCKER_BUILD_ARGS is defined ${happy_smiley} : ${DOCKER_BUILD_ARGS} ${NC}"
else
  echo -e "${red} ${double_arrow} Undefined build parameter ${head_skull} : DOCKER_BUILD_ARGS, use the default one ${NC}"
  export DOCKER_BUILD_ARGS="--pull --build-arg ANSIBLE_VAULT_PASS=${ANSIBLE_VAULT_PASS} "
  #export DOCKER_BUILD_ARGS="--pull"
  #export DOCKER_BUILD_ARGS="--build-arg --no-cache"
  echo -e "${magenta} DOCKER_BUILD_ARGS : ${DOCKER_BUILD_ARGS} ${NC}"
fi

echo -e "${green} Building docker image ${NC}"
echo -e "${magenta} time docker build ${DOCKER_BUILD_ARGS} -f ${WORKING_DIR}/${DOCKER_FILE} -t \"$DOCKER_ORGANISATION/$DOCKER_NAME\" -t \"${DOCKER_ORGANISATION}/${DOCKER_NAME}:${DOCKER_TAG}\" ${WORKING_DIR}/../ ${NC}"
time docker build ${DOCKER_BUILD_ARGS} -f ${WORKING_DIR}/${DOCKER_FILE} -t "${DOCKER_ORGANISATION}/${DOCKER_NAME}" -t "${DOCKER_ORGANISATION}/${DOCKER_NAME}:${DOCKER_TAG}" ${WORKING_DIR}/../ | tee docker.log
RC=$?
if [ ${RC} -ne 0 ]; then
  echo ""
  # shellcheck disable=SC2154
  echo -e "${red} ${head_skull} Sorry, build failed. ${NC}"
  exit 1
else
  echo -e "${green} The build completed successfully. ${NC}"
  echo -e "${magenta} Running docker history to docker history ${NC}"
  echo -e "    docker history --no-trunc ${DOCKER_ORGANISATION}/${DOCKER_NAME}:latest > docker-history.log"
  docker history --no-trunc ${DOCKER_ORGANISATION}/${DOCKER_NAME}:latest > docker-history.log 2>&1
  echo -e "${magenta} Running dive ${NC}"
  echo -e "    dive ${DOCKER_ORGANISATION}/${DOCKER_NAME}:latest"
  CI=true dive "${DOCKER_ORGANISATION}/${DOCKER_NAME}:latest" || true > docker-dive.log
  RC=$?
  if [ ${RC} -ne 0 ]; then
    echo ""
    echo -e "${red} ${head_skull} Sorry, dive failed ${NC}"
    #exit 1
  fi
fi

echo -e ""
echo -e "${green} This image is a trusted docker hub Image. ${happy_smiley} ${NC}"
echo -e "See https://hub.docker.com/r/nabla/ansible-jenkins-slave-docker/"
echo -e ""
echo -e "To push it"
echo -e "    docker login ${DOCKER_REGISTRY} --username ${DOCKER_USERNAME} --password password"
echo -e "    docker tag ${DOCKER_ORGANISATION}/${DOCKER_NAME}:latest ${DOCKER_REGISTRY}${DOCKER_ORGANISATION}/${DOCKER_NAME}:${DOCKER_TAG}"
echo -e "    docker tag ${DOCKER_ORGANISATION}/${DOCKER_NAME}:latest ${DOCKER_REGISTRY}${DOCKER_ORGANISATION}/${DOCKER_NAME}:latest"
echo -e "    docker push ${DOCKER_REGISTRY}${DOCKER_ORGANISATION}/${DOCKER_NAME}:latest"
echo -e ""
echo -e "To pull it"
echo -e "    docker pull ${DOCKER_REGISTRY}${DOCKER_ORGANISATION}/${DOCKER_NAME}:${DOCKER_TAG}"
echo -e ""
echo -e "To use this docker:"
echo -e "    docker run -d -P ${DOCKER_ORGANISATION}/${DOCKER_NAME}"
echo -e " - to attach your container directly to the host's network interfaces"
echo -e "    docker run --net host -d -P ${DOCKER_ORGANISATION}/${DOCKER_NAME}"
echo -e ""
export JENKINS_USER_HOME=${JENKINS_USER_HOME:-/data1/home/jenkins/}
export USER=${USER:-albandri}
export GROUP=${GROUP:-docker}
export DOCKER_UID=${DOCKER_UID:-1000}
export DOCKER_GID=${DOCKER_GID:-2000}
# shellcheck disable=SC2059
printf "\033[1;32mFROM UID:GID: ${DOCKER_UID}:${DOCKER_GID}- JENKINS_USER_HOME: ${JENKINS_USER_HOME} \033[0m\n" && \
printf "\033[1;32mWITH $USER\ngroup: $GROUP \033[0m\n"

echo -e "${green} User is : ${NC}"
id "${USER}"
echo -e "${magenta} Add docker group to above user. ${happy_smiley} ${NC}"
echo -e "${magenta} sudo usermod -a -G docker ${USER} ${NC}"

echo -e "To run in interactive mode for debug:"
echo -e "    docker run -it -u ${DOCKER_UID}:${DOCKER_GID} --userns=host -v ${JENKINS_USER_HOME}:/home/jenkins -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro -v /var/run/docker.sock:/var/run/docker.sock --entrypoint /bin/bash ${DOCKER_ORGANISATION}/${DOCKER_NAME}:latest"
echo -e "    docker run -it -d -u ${DOCKER_UID}:${DOCKER_GID} --userns=host --name sandbox ${DOCKER_ORGANISATION}/${DOCKER_NAME}:latest cat"
echo -e "    docker exec -it sandbox /bin/bash"
echo -e "    docker exec -u 0 -it sandbox env TERM=xterm-256color bash -l"
echo -e ""

echo -e "${magenta} Run CST test ${NC}"
echo -e "${magenta} ${WORKING_DIR}/docker-test.sh ${DOCKER_NAME} ${NC}"

#git tag -l | xargs git tag -d # remove all local tags
#git fetch -t                  # fetch remote tags

echo -e ""
echo -e "${green} Please valide the repo. ${happy_smiley} ${NC}"
echo -e "${magenta} git tag ${DOCKER_TAG} ${NC}"
echo -e "${magenta} git push origin --tags ${NC}"
echo -e ""

exit 0
