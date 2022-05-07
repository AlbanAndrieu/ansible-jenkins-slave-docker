#!/bin/bash
#set -xv
shopt -s extglob

#set -ueo pipefail
set -eo pipefail

WORKING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export DOCKER_TAG=${DOCKER_TAG:-"1.1.18"}

if [[ -z $ANSIBLE_VAULT_PASSWORD ]]; then
  echo "Provide vault ANSIBLE_VAULT_PASSWORD password as environement variable before launching the script. Exit."
  exit 1
fi

if [ -n "${DOCKER_BUILD_ARGS}" ]; then
  echo -e "${green} DOCKER_BUILD_ARGS is defined : overiding ${happy_smiley} : ${DOCKER_BUILD_ARGS} ${NC}"
else
  echo -e "${red} ${double_arrow} Undefined build parameter ${head_skull} : DOCKER_BUILD_ARGS, use the default one ${NC}"
  export DOCKER_BUILD_ARGS="--pull --network=host --add-host albandrieu.com:192.168.132.24 --build-arg ANSIBLE_VAULT_PASSWORD=${ANSIBLE_VAULT_PASSWORD} --no-cache"
  #export DOCKER_BUILD_ARGS="--build-arg --no-cache --squash"
  echo -e "${magenta} DOCKER_BUILD_ARGS : ${DOCKER_BUILD_ARGS} ${NC}"
fi

export DOCKER_FILE=${DOCKER_FILE:-"../docker/ubuntu18/Dockerfile"}
export CST_CONFIG=${CST_CONFIG:-"docker/ubuntu18/config.yaml"}

# shellcheck source=/dev/null
source "${WORKING_DIR}/docker-env.sh"

echo -e "${green} Validating Docker ${NC}"
echo -e "${magenta} hadolint ${WORKING_DIR}/${DOCKER_FILE} --format json ${NC}"
hadolint "${WORKING_DIR}/${DOCKER_FILE}" --format json 1>docker-hadolint.json 2>docker-hadolint-error.log || true
echo -e "${magenta} dockerfile_lint --json --verbose --dockerfile ${WORKING_DIR}/${DOCKER_FILE} ${NC}"
dockerfile_lint --json --verbose --dockerfile "${WORKING_DIR}/${DOCKER_FILE}" 1>docker-dockerfilelint.json 2>docker-dockerfilelint-error.log || true

# shellcheck source=/dev/null
#source "${WORKING_DIR}/run-ansible.sh"

WORKING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"${WORKING_DIR}/../clean.sh"

echo -e "${green} Installing key for Docker ${NC}"
mkdir -p .ssh/
#wget http://bm-artifacts.misys.global.ad/nexus/content/repositories/fusion-risk/download/certs/id_rsa.pub -O ${WORKING_DIR}/../.ssh/id_rsa.pub && chmod 600 ${HOME}/.ssh/id_rsa.pub
#cp -p /home/kgr_mvn/.ssh/id_rsa* ${WORKING_DIR}/../.ssh/ || true

export DOCKER_BUILDKIT=1

echo -e "${green} Building docker image ${NC}"
echo -e "${magenta} time docker build ${DOCKER_BUILD_ARGS} -f ${WORKING_DIR}/${DOCKER_FILE} -t \"${DOCKER_ORGANISATION}/${DOCKER_NAME}\" -t \"${DOCKER_ORGANISATION}/${DOCKER_NAME}:${DOCKER_TAG}\" ${WORKING_DIR}/../ ${NC}"
time docker build ${DOCKER_BUILD_ARGS} -f ${WORKING_DIR}/${DOCKER_FILE} -t "${DOCKER_ORGANISATION}/${DOCKER_NAME}" -t "${DOCKER_ORGANISATION}/${DOCKER_NAME}:${DOCKER_TAG}" ${WORKING_DIR}/../ | tee docker.log
RC=$?
if [ ${RC} -ne 0 ]; then
  echo ""
  # shellcheck disable=SC2154
  echo -e "${red} ${head_skull} Sorry, build failed. ${NC}"
  exit 1
else
  echo -e "${green} The build completed successfully. ${NC}"
  ${WORKING_DIR}/docker-inspect.sh
fi

echo -e ""
echo -e "${green} This image is a trusted docker Image. ${happy_smiley} ${NC}"
echo -e ""
echo -e "To push it"
echo -e "    docker login ${DOCKER_REGISTRY} --username ${DOCKER_USERNAME} --password password"
#echo -e "    docker tag ${DOCKER_ORGANISATION}/${DOCKER_NAME}:${DOCKER_TAG} ${DOCKER_REGISTRY}${DOCKER_ORGANISATION}/${DOCKER_NAME}:${DOCKER_TAG}"
#echo -e "    docker tag ${DOCKER_ORGANISATION}/${DOCKER_NAME}:${DOCKER_TAG} ${DOCKER_REGISTRY}${DOCKER_ORGANISATION}/${DOCKER_NAME}:latest"
#echo -e "    docker tag ${DOCKER_ORGANISATION}/${DOCKER_NAME}:${DOCKER_TAG} ${DOCKER_REGISTRY_TMP}${DOCKER_ORGANISATION}/${DOCKER_NAME}:latest"
echo -e "    docker tag ${DOCKER_ORGANISATION}/${DOCKER_NAME}:${DOCKER_TAG} ${DOCKER_REGISTRY_ACR}${DOCKER_ORGANISATION}/${DOCKER_NAME}:${DOCKER_TAG}"
echo -e "    docker tag ${DOCKER_ORGANISATION}/${DOCKER_NAME}:${DOCKER_TAG} ${DOCKER_REGISTRY_ACR}${DOCKER_ORGANISATION}/${DOCKER_NAME}:latest"
echo -e "    docker push ${DOCKER_REGISTRY_ACR}${DOCKER_ORGANISATION}/${DOCKER_NAME}:latest"

echo -e "    docker manifest inspect  ${DOCKER_REGISTRY_ACR}${DOCKER_ORGANISATION}/${DOCKER_NAME}:latest"

echo -e ""
echo -e "To pull it"
echo -e "    docker pull ${DOCKER_REGISTRY_ACR}${DOCKER_ORGANISATION}/${DOCKER_NAME}:${DOCKER_TAG}"
echo -e ""
echo -e "To use this docker:"
echo -e "    docker run -d -P ${DOCKER_ORGANISATION}/${DOCKER_NAME}"
echo -e " - to attach your container directly to the host's network interfaces"
echo -e "    docker run --net host -d -P ${DOCKER_ORGANISATION}/${DOCKER_NAME}"
echo -e ""
export JENKINS_USER_HOME=${JENKINS_USER_HOME:-/data1/home/jenkins/}
export USER=${USER:-albandri}
export GROUP=${GROUP:-docker}
export DOCKER_UID=${DOCKER_UID:-1004}
export DOCKER_GID=${DOCKER_GID:-999}
# shellcheck disable=SC2059
printf "\033[1;32mFROM UID:GID: ${DOCKER_UID}:${DOCKER_GID}- JENKINS_USER_HOME: ${JENKINS_USER_HOME} \033[0m\n" &&
  printf "\033[1;32mWITH ${USER}\ngroup: ${GROUP} \033[0m\n"

echo -e "${green} User is. ${happy_smiley} : ${NC}"
id "${USER}"
echo -e "${magenta} Add docker group to above user. ${happy_smiley} ${NC}"
echo -e "${magenta} sudo usermod -a -G docker ${USER} ${NC}"

echo -e "To run in interactive mode for debug:"
echo -e "    docker run --init -it -u ${DOCKER_UID}:${DOCKER_GID} --userns=host -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro -v /var/run/docker.sock:/var/run/docker.sock --entrypoint /bin/bash ${DOCKER_ORGANISATION}/${DOCKER_NAME}:latest"
echo -e ""
echo -e "     -v ${JENKINS_USER_HOME}:/home/jenkins"
echo -e ""
echo -e "    docker run --init -it -d -u ${DOCKER_UID}:${DOCKER_GID} --userns=host --name sandbox ${DOCKER_ORGANISATION}/${DOCKER_NAME}:latest cat"
echo -e "    Note: --init is necessary for correct subprocesses handling (zombie reaping)"

export JENKINS_URL=${JENKINS_URL:="http://albandrieu/jenkins"}
#export JENKINS_CRUMB=$(curl "$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")
echo -e "JENKINS_CRUMB : ${JENKINS_CRUMB} ${NC}"
export JENKINS_AGENT_NAME=${JENKINS_AGENT_NAME:="docker-test"}
#export JENKINS_SECRET=$(curl -L -s -u admin:password -H "Jenkins-Crumb:${JENKINS_CRUMB}" -X GET ${JENKINS_URL}/computer/docker-test/slave-agent.jnlp | sed "s/.*<application-desc main-class=\"hudson.remoting.jnlp.Main\"><argument>\([a-z0-9]*\).*/\1/")
echo -e "JENKINS_SECRET : ${JENKINS_SECRET} ${NC}"

echo -e "    docker run --init ${DOCKER_ORGANISATION}/${DOCKER_NAME}:latest /usr/local/bin/jenkins-agent -url ${JENKINS_URL} -workDir=/home/jenkins/agent ${JENKINS_SECRET} ${JENKINS_AGENT_NAME} ${NC}"
echo -e "    docker exec -it sandbox /bin/bash ${NC}"
echo -e "    docker exec -u 0 -it sandbox env TERM=xterm-256color bash -l ${NC}"
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
