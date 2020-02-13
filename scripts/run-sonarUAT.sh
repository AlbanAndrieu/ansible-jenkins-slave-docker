#!/bin/sh

#git pull
ansible-playbook java-certificate.yml -i hosts -vvvv --sudo
ansible-playbook sonar-UAT.yml -i hosts -vvvv --sudo --timeout=30
