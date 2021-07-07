#!/bin/bash
set -e

WORKING_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )"

# shellcheck source=/dev/null
source "${WORKING_DIR}/run-ansible.sh"

echo "ansible-inventory -i ${WORKING_DIR}/../inventory/hosts --graph"
ansible-inventory -i ${WORKING_DIR}/../inventory/hosts --graph # > inventory.log

echo "${ANSIBLE_GALAXY_CMD} -i ${WORKING_DIR}/../inventory/hosts -c local ${WORKING_DIR}/../playbooks/jenkins-slave-docker.yml -vvvv --check --diff --ask-become-pass"
echo "${ANSIBLE_GALAXY_CMD} -i ${WORKING_DIR}/../inventory/hosts -c local ${WORKING_DIR}/../playbooks/jenkins-slave-docker.yml -vvvv --ask-become-pass"

exit 0
