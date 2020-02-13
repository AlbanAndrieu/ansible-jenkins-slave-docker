#!/bin/bash
set -e

echo "ansible-playbook -i inventory/hosts -c local -v playbooks/jenkins-slave-docker.yml --check --diff --ask-become-pass -vvvv"

exit 0
