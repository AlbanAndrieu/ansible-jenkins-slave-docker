#!/bin/bash
#set -xve

WORKING_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )"

export TARGET_PLAYBOOK=${TARGET_PLAYBOOK:-jenkins*.yml}
# shellcheck source=/dev/null

source "${WORKING_DIR}/ansible-env.sh"

echo -e "${cyan} =========== ${NC}"
echo -e "${green} Ansible lint ${NC}"
echo -e "${magenta} ${ANSIBLE_LINT_CMD} -p ${WORKING_DIR}/../playbooks/${TARGET_PLAYBOOK} > ${WORKING_DIR}/../ansible-lint.txt ${NC}"
${ANSIBLE_LINT_CMD} -p ${WORKING_DIR}/../playbooks/${TARGET_PLAYBOOK} > ${WORKING_DIR}/../ansible-lint.txt
RC=$?
if [ ${RC} -ne 0 ]; then
  echo ""
  echo -e "${red} ${head_skull} Sorry, ansible lint failed ${NC}"
  #exit 1
fi
echo -e "${magenta} ansible-lint-junit ${WORKING_DIR}/../ansible-lint.txt -o ${WORKING_DIR}/../ansible-lint.xml ${NC}"
ansible-lint-junit ${WORKING_DIR}/../ansible-lint.txt -o ${WORKING_DIR}/../ansible-lint.xml

exit 0
