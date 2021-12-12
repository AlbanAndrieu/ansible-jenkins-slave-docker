#!/bin/bash
#set -xve

if [ -d "${WORKSPACE}/ansible" ]; then
  cd "${WORKSPACE}/ansible" || exit
fi

WORKING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#export PYTHON_MAJOR_VERSION=3.7

# shellcheck source=/dev/null
source "${WORKING_DIR}/run-python.sh"
RC=$?
if [ ${RC} -ne 0 ]; then
  echo ""
  echo -e "${red} ${head_skull} Sorry, python 3.6 basics failed ${NC}"
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

# check syntax
echo -e "${cyan} =========== ${NC}"
echo -e "${green} Starting the syntax-check. ${NC}"
echo -e "${magenta} ${ANSIBLE_PLAYBOOK_CMD} -i ${ANSIBLE_INVENTORY} -c local -v playbooks/${TARGET_PLAYBOOK} --limit ${TARGET_SLAVE} ${DRY_RUN} -vvvv --syntax-check --become-method=sudo ${NC}"
${ANSIBLE_PLAYBOOK_CMD} -i ${ANSIBLE_INVENTORY} -v playbooks/${TARGET_PLAYBOOK} --limit ${TARGET_SLAVE} ${DRY_RUN} -vvvv --syntax-check --become-method=sudo | tee syntax-check.log
RC=$?
if [ ${RC} -ne 0 ]; then
  echo ""
  echo -e "${red} ${head_skull} Sorry, syntax-check failed ${NC}"
  exit 1
else
  echo -e "${green} The syntax-check completed successfully. ${NC}"
fi

echo -e "${cyan} =========== ${NC}"
echo -e "${green} Starting the playbook. ${NC}"
if [ "${DOCKER_RUN}" == "" ]; then
  echo -e "${red} \u00BB Undefined build parameter ${head_skull} : DOCKER_RUN${NC}"
  "${WORKING_DIR}/setup.sh"
else
  "${WORKING_DIR}/../build.sh"
fi

${WORKING_DIR}/run-ansible-cmbd.sh
RC=$?
if [ ${RC} -ne 0 ]; then
  echo ""
  echo -e "${red} ${head_skull} Sorry, ansible inventory failed ${NC}"
  exit 1
fi

cd "${WORKSPACE}/bm/Scripts/shell" || exit

echo -e "${cyan} =========== ${NC}"
shellcheck ./*.sh -f checkstyle >checkstyle-result.xml || true
echo -e "${green} shell check for shell done. $? ${NC}"

echo -e "${cyan} =========== ${NC}"
cd "${WORKSPACE}/scripts/" || exit
shellcheck ./*.sh -f checkstyle >checkstyle-result.xml || true
echo -e "${green} shell check for release done. $? ${NC}"

echo -e "${cyan} =========== ${NC}"
cd "${WORKSPACE}/.." || exit # pylint need .pylintrc
if [ -f ".pylintrc" ]; then
  pylint --output-format=junit ./**/*.py >pylint-junit-result.xml || true
  echo -e "${green} python check for pylint done. $? ${NC}"
fi

#pyreverse -o png -p Pyreverse pylint/pyreverse/

echo -e "${green} ansible junit output is in ${JUNIT_OUTPUT_DIR} ${NC}"

exit 0
