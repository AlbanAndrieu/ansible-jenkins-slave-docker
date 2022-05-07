#!/bin/bash
#set -xv
shopt -s extglob

set -eo pipefail

WORKING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export DOCKER_TAG=${DOCKER_TAG:-"2.0.0"}

# shellcheck source=/dev/null
source "${WORKING_DIR}/docker-env.sh"

echo -e "${green} Inspect docker image ${NC}"

echo -e "${magenta} Running docker history to docker history ${NC}"
echo -e "    docker history --no-trunc ${DOCKER_ORGANISATION}/${DOCKER_NAME}:latest > docker-history.log"
docker history --no-trunc ${DOCKER_ORGANISATION}/${DOCKER_NAME}:latest 1>docker-history.log 2>docker-history-error.log || true
echo -e "${magenta} Running dive ${NC}"
echo -e "    dive ${DOCKER_ORGANISATION}/${DOCKER_NAME}:latest"
CI=true dive --ci --json docker-dive-stats.json "${DOCKER_ORGANISATION}/${DOCKER_NAME}:latest" 1>docker-dive.log 2>docker-dive-error.log || true
RC=$?
if [ ${RC} -ne 0 ]; then
  echo ""
  echo -e "${red} ${head_skull} Sorry, dive failed ${NC}"
  #exit 1
fi

echo -e ""
echo -e "${green} Check with dockviz. ${happy_smiley} ${NC}"
docker pull nate/dockviz
alias dockviz="docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock nate/dockviz"
echo -e "${magenta} dockviz containers -d -r | dot -Tpng -o containers-running.png ${NC}"
echo -e "${magenta} dockviz images -d | dot -Tpng -o images.png ${NC}"
echo -e ""

export DOCKER_REGISTRY=${DOCKER_REGISTRY:-"https://hub.docker.com/"}

echo -e "${magenta}skopeo login docker.io ${NC}"
#skopeo login -u testuser -p testpassword localhost:5000
echo -e "${magenta} skopeo login ${DOCKER_REGISTRY} --username $SP_APP_ID --password $SP_PASSWD ${NC}"

echo -e "${magenta} skopeo inspect docker://${DOCKER_REGISTRY}/${DOCKER_ORGANISATION}/${DOCKER_NAME}:latest ${NC}"
# TODO insecure password to be fixed with docker secret https://docs.docker.com/engine/swarm/secrets/
# See https://docs.ansible.com/ansible/2.8/user_guide/playbooks_vault.html
echo -e "${magenta} skopeo inspect docker://${DOCKER_REGISTRY}/${DOCKER_ORGANISATION}/${DOCKER_NAME}:latest | grep ANSIBLE_VAULT_PASSWORD ${NC}"
echo -e ""

export DOCKER_FILE=${DOCKER_FILE:-"../docker/ubuntu20/Dockerfile"}

echo -e "${magenta} sudo lynis audit dockerfile ${DOCKER_FILE} ${NC}"
echo -e ""

exit 0
