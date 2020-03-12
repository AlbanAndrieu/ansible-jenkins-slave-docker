#!/bin/bash
set -e

WORKING_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )"

# shellcheck source=/dev/null
source "${WORKING_DIR}/run-ansible.sh"

ansible-inventory -i inventory/hosts --graph

echo "${ANSIBLE_GALAXY_CMD} -i inventory/hosts -c local playbooks/jenkins-slave-docker.yml -vvvv --check --diff --ask-become-pass"
echo "${ANSIBLE_GALAXY_CMD} -i inventory/hosts -c local playbooks/jenkins-slave-docker.yml -vvvv --ask-become-pass"

exit 0
