#!/bin/bash
set -e

ansible-inventory -i inventory/hosts --graph

echo "ansible-playbook -i inventory/hosts -c local playbooks/jenkins-slave-docker.yml -vvvv --check --diff --ask-become-pass"
echo "ansible-playbook -i inventory/hosts -c local playbooks/jenkins-slave-docker.yml -vvvv --ask-become-pass"

exit 0
