#!/bin/bash
#set -xve

WORKING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Forcing ansible cmd to use python3.7
#export PYTHON_MAJOR_VERSION=3.7

# shellcheck source=/dev/null
source "${WORKING_DIR}/run-python.sh"
RC=$?
if [ ${RC} -ne 0 ]; then
  echo ""
  echo -e "${red} ${head_skull} Sorry, python 3.6 basics failed ${NC}"
  exit 1
fi

"${WORKING_DIR}/run-ansible-lint.sh"
RC=$?
if [ ${RC} -ne 0 ]; then
  echo ""
  echo -e "${red} ${head_skull} Sorry, ansible lint failed ${NC}"
  exit 1
fi

# shellcheck source=/dev/null
source "${WORKING_DIR}/run-ansible.sh"
RC=$?
if [ ${RC} -ne 0 ]; then
  echo ""
  echo -e "${red} ${head_skull} Sorry, ansible basics failed ${NC}"
  exit 1
fi

rm -Rf ${WORKING_DIR}/../${JUNIT_OUTPUT_DIR} || true
mkdir ${WORKING_DIR}/../${JUNIT_OUTPUT_DIR}

echo -e "${cyan} =========== ${NC}"
echo -e "${green} Ansible server setup ${NC}"
echo -e "${magenta} ${ANSIBLE_CMD} -i ${WORKING_DIR}/../${ANSIBLE_INVENTORY} -m setup -vvvv --tree ${WORKING_DIR}/../${JUNIT_OUTPUT_DIR} all ${NC}"
${ANSIBLE_CMD} -i ${WORKING_DIR}/../${ANSIBLE_INVENTORY} -m setup -vvvv --tree ${WORKING_DIR}/../${JUNIT_OUTPUT_DIR} all >inventory-setup.log 2>&1
RC=$?
if [ ${RC} -ne 0 ]; then
  echo ""
  echo -e "${yellow} Warning, setup failed ${NC}"
  #This might fail for hosts which are UNREACHABLE
  #exit 1
else
  echo -e "${green} The setup completed successfully. ${NC}"
fi

echo -e "${cyan} =========== ${NC}"
echo -e "${green} Ansible server inventory HTML generation ${NC}"
${ANSIBLE_CMBD_CMD} --version
echo -e "${magenta} ${ANSIBLE_CMBD_CMD} -d -i ${WORKING_DIR}/../${ANSIBLE_INVENTORY} ${WORKING_DIR}/../${ANSIBLE_INVENTORY_OUTPUT_DIR} > overview.html ${NC}"
${ANSIBLE_CMBD_CMD} -d -i ${WORKING_DIR}/../${ANSIBLE_INVENTORY} ${WORKING_DIR}/../${ANSIBLE_INVENTORY_OUTPUT_DIR} >overview.html
RC=$?
if [ ${RC} -ne 0 ]; then
  echo ""
  echo -e "${red} ${head_skull} Sorry, inventory generation failed ${NC}"
  exit 1
else
  echo -e "${green} The inventory generation completed successfully. ${NC}"
fi
echo -e "${magenta} cp overview.html /var/www/html/ ${NC}"
cp overview.html /var/www/html/ || true
echo -e "${green} Ansible server summary done. $? ${NC}"

echo -e "${green} See http://${TARGET_SLAVE}/html/overview.html ${NC}"

exit 0
