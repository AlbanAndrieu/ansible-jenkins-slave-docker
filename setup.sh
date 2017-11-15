#!/bin/bash
#set -xv

#bold="\033[01m"
#underline="\033[04m"
#blink="\033[05m"

#black="\033[30m"
red="\033[31m"
green="\033[32m"
#yellow="\033[33m"
#blue="\033[34m"
#magenta="\033[35m"
#cyan="\033[36m"
#ltgray="\033[37m"

NC="\033[0m"

#double_arrow='\xC2\xBB'
head_skull='\xE2\x98\xA0'
happy_smiley='\xE2\x98\xBA'
reverse_exclamation='\u00A1'

if [ -n "${TARGET_SLAVE}" ]; then
  echo -e "${green} TARGET_SLAVE is defined ${happy_smiley} ${NC}"
else
  echo -e "${red} \u00BB Undefined build parameter ${head_skull} : TARGET_SLAVE, use the default one ${NC}"
  export TARGET_SLAVE=localhost
fi

if [ -n "${TARGET_PLAYBOOK}" ]; then
  echo -e "${green} TARGET_PLAYBOOK is defined ${happy_smiley} ${NC}"
else
  echo -e "${red} \u00BB Undefined build parameter ${head_skull} : TARGET_PLAYBOOK, use the default one ${NC}"
  export TARGET_PLAYBOOK=jenkins-slave-docker.yml
fi

if [ -n "${DRY_RUN}" ]; then
  echo -e "${green} DRY_RUN is defined ${happy_smiley} ${NC}"
else
  echo -e "${red} \u00BB Undefined build parameter ${head_skull} : DRY_RUN, use the default one ${NC}"
  export DRY_RUN="--check"
fi

type -p ansible-playbook > /dev/null
if [ $? -ne 0 ]; then
    echo -e "${red} \u00BB Oops! I cannot find ansible.  Please be sure to install ansible before proceeding. ${NC}"
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
fi

getopts "e:" EXTRA_ARGS
if [ "$OPTARG" != "" ]; then
    echo -e "${green} Running with extra args: ${OPTARG} ${NC}"
    #-c local  --become-method=sudo
    PYTHONUNBUFFERED=x ANSIBLE_FORCE_COLOR=$ANSIBLE_FORCE_COLOR ANSIBLE_ERROR_ON_UNDEFINED_VARS=True ansible-playbook -i staging -vvvv --limit ${TARGET_SLAVE} ${DRY_RUN} -e "$OPTARG" ${TARGET_PLAYBOOK} | tee setup.log
else
    PYTHONUNBUFFERED=x ANSIBLE_FORCE_COLOR=$ANSIBLE_FORCE_COLOR ANSIBLE_ERROR_ON_UNDEFINED_VARS=True ansible-playbook -i staging -vvvv --limit ${TARGET_SLAVE} ${DRY_RUN} ${TARGET_PLAYBOOK} -vvvv | tee setup.log
fi
RC=$?
if [ ${RC} -ne 0 ]; then
    echo -e "${red} ${head_skull} Sorry, playboook failed ${NC}"
else
    echo -e "${green} playboook succeed. ${NC}"
    #ansible-playbook -i staging ${TARGET_PLAYBOOK} -vvvv --limit ${TARGET_SLAVE} ${DRY_RUN} --become-method=sudo | grep -q 'unreachable=0.*failed=0' && (echo 'Main test: pass' && exit 0) || (echo 'Main test: fail' && exit 1)
fi

echo -e "${green} Ansible done. $? ${NC}"  
    
# Save logfile
if [ -d "${LOG_DIR}" ]; then
    sudo cp setup.log "${LOG_FILE}"
    echo -e "${green} Setup log saved to ${LOG_FILE} ${NC}"
fi

exit ${RC}
