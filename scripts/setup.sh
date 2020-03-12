#!/bin/bash
#set -xv

WORKING_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )"

# source only if terminal supports color, otherwise use unset color vars
# shellcheck source=/dev/null
source "${WORKING_DIR}/step-0-color.sh"

# shellcheck source=/dev/null
source "${WORKING_DIR}/ansible-env.sh"

type -p "${ANSIBLE_PLAYBOOK_CMD}" > /dev/null
RC=$?
if [ ${RC} -ne 0 ]; then
    echo -e "${red} \u00BB Oops! I cannot find ansible ${ANSIBLE_PLAYBOOK_CMD}.  Please be sure to install ansible before proceeding. ${NC}"
    echo -e "${red} \u00BB For guidance on installing ansible, consult http://docs.ansible.com/intro_installation.html. ${NC}"
    exit 1
fi

#export ANSIBLE_DEBUG=1

# Allow exit codes to trickle through a pipe
set -o pipefail

TIMESTAMP=$(date --utc +"%F-%T")
LOG_DIR="/var/log/awx"
LOG_FILE="${LOG_DIR}/setup-${TIMESTAMP}.log"

# When using an interactive shell, force colorized ansible output
if [ -t "0" ]; then
    ANSIBLE_FORCE_COLOR=True
else
    ANSIBLE_FORCE_COLOR=False
fi

echo -e "${green} Installing key for Docker ${NC}"
mkdir -p .ssh/
cp -p /home/kgr_mvn/.ssh/id_rsa* .ssh/ || true

# shellcheck disable=SC2034
getopts "e:" EXTRA_ARGS
if [ "$OPTARG" != "" ]; then
    echo -e "${green} Running with extra args: ${OPTARG} ${NC}"
    echo -e "${magenta} x ANSIBLE_FORCE_COLOR=$ANSIBLE_FORCE_COLOR ANSIBLE_ERROR_ON_UNDEFINED_VARS=True ${ANSIBLE_PLAYBOOK_CMD} -i ${WORKING_DIR}/../${ANSIBLE_INVENTORY} -vvvv --limit ${TARGET_SLAVE} ${DRY_RUN} -e \"$OPTARG\" ${WORKING_DIR}/../playbooks/${TARGET_PLAYBOOK} ${NC}"
    PYTHONUNBUFFERED=x ANSIBLE_FORCE_COLOR=$ANSIBLE_FORCE_COLOR ANSIBLE_ERROR_ON_UNDEFINED_VARS=True ${ANSIBLE_PLAYBOOK_CMD} -i ${WORKING_DIR}/../${ANSIBLE_INVENTORY} -vvvv --limit ${TARGET_SLAVE} ${DRY_RUN} -e "$OPTARG" ${WORKING_DIR}/../playbooks/${TARGET_PLAYBOOK} | tee setup.log
else
    echo -e "${magenta} x ANSIBLE_FORCE_COLOR=$ANSIBLE_FORCE_COLOR ANSIBLE_ERROR_ON_UNDEFINED_VARS=True ${ANSIBLE_PLAYBOOK_CMD} -i ${WORKING_DIR}/../${ANSIBLE_INVENTORY} -vvvv --limit ${TARGET_SLAVE} ${DRY_RUN} ${WORKING_DIR}/../playbooks/${TARGET_PLAYBOOK} -vvvv ${NC}"
    PYTHONUNBUFFERED=x ANSIBLE_FORCE_COLOR=$ANSIBLE_FORCE_COLOR ANSIBLE_ERROR_ON_UNDEFINED_VARS=True ${ANSIBLE_PLAYBOOK_CMD} -i ${WORKING_DIR}/../${ANSIBLE_INVENTORY} -vvvv --limit ${TARGET_SLAVE} ${DRY_RUN} ${WORKING_DIR}/../playbooks/${TARGET_PLAYBOOK} | tee setup.log
fi
RC=$?
if [ ${RC} -ne 0 ]; then
    echo -e "${red} ${head_skull} Sorry, playboook failed ${NC}"
else
    echo -e "${green} playboook succeed. ${NC}"
    #${ANSIBLE_PLAYBOOK_CMD} -i ${ANSIBLE_INVENTORY} playbooks/${TARGET_PLAYBOOK} -vvvv --limit ${TARGET_SLAVE} ${DRY_RUN} --become-method=sudo | grep -q 'unreachable=0.*failed=0' && (echo 'Main test: pass' && exit 0) || (echo 'Main test: fail' && exit 1)
fi

echo -e "${green} Ansible done. $? ${NC}"

# Save logfile
if [ -d "${LOG_DIR}" ]; then
    sudo cp setup.log "${LOG_FILE}"
    echo -e "${green} Setup log saved to ${LOG_FILE} ${NC}"
fi

exit ${RC}
