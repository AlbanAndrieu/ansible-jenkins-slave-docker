#!/bin/bash
#set -xve

WORKING_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )"

# source only if terminal supports color, otherwise use unset color vars
# shellcheck source=/dev/null
source "${WORKING_DIR}/step-0-color.sh"

# shellcheck source=/dev/null
source "${WORKING_DIR}/step-1-os.sh"

# shellcheck source=/dev/null
source "${WORKING_DIR}/ansible-env.sh"

echo -e "${cyan} =========== ${NC}"
echo -e "${green} Ansible vault password. ${NC}"

if [ -c "${WORKING_DIR}/../vault.passwd" ]; then
  echo -e "${green} ${WORKING_DIR}/../vault.passwd exist ${happy_smiley} : *** ${NC}"
else
  if [ -n "${ANSIBLE_VAULT_PASS}" ]; then
    echo -e "${green} ANSIBLE_VAULT_PASS is defined ${happy_smiley} : *** ${NC}"
    #echo "${ANSIBLE_VAULT_PASS}" > ${WORKING_DIR}/../vault.passwd || true
  else
    echo -e "${red} ${double_arrow} Undefined build parameter ${head_skull} : ANSIBLE_VAULT_PASS, use the default one ${NC}"
    #exit 1
  fi
fi

lsb_release -a

# DOCKER
export DOCKER_CLIENT_TIMEOUT=240
export COMPOSE_HTTP_TIMEOUT=2000

echo -e " ======= Running on ${TARGET_SLAVE} ${reverse_exclamation} ${NC}"
echo "USER : $USER"
echo "HOME : $HOME"
echo "WORKSPACE : $WORKSPACE"

echo "DOCKER_CLIENT_TIMEOUT : $DOCKER_CLIENT_TIMEOUT"
echo "COMPOSE_HTTP_TIMEOUT : $COMPOSE_HTTP_TIMEOUT"

#tomcat8 must be stop to no use same port
#${USE_SUDO} service tomcat8 stop || true

echo -e "${cyan} =========== ${NC}"
echo -e "${green} Checking ansible version ${NC}"

which ansible
ansible --version | grep python || true
RC=$?
if [ ${RC} -ne 0 ]; then
  echo ""
  echo -e "${red} ${head_skull} Sorry, ansible basics failed ${NC}"
  exit 1
fi

echo -e "${magenta} ANSIBLE_CMD : Version ${NC}"
${ANSIBLE_CMD} --version || true
echo -e "${magenta} ANSIBLE_GALAXY_CMD : Version ${NC}"
${ANSIBLE_GALAXY_CMD} --version || true

# shellcheck source=/dev/null
#source "${WORKING_DIR}/run-ansible-setup.sh"

#exit 0
