#!/bin/bash
#set -xv

WORKING_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )"

# shellcheck source=/dev/null
source "${WORKING_DIR}/step-1-os.sh"

function float_gt() {
    perl -e "{if($1>$2){print 1} else {print 0}}"
}

function versionToInt() {
  local IFS=.
  parts=($1)
  let val=1000000*parts[0]+1000*parts[1]+parts[2]
  echo $val
}

if [ -n "${TARGET_SLAVE}" ]; then
  echo -e "${green} TARGET_SLAVE is defined ${happy_smiley} : ${TARGET_SLAVE} ${NC}"
else
  echo -e "${red} ${double_arrow} Undefined build parameter ${head_skull} : TARGET_SLAVE, use the default one ${NC}"
  export TARGET_SLAVE=albandrieu.com
  echo -e "${magenta} TARGET_SLAVE : ${TARGET_SLAVE} ${NC}"
fi

if [ -n "${TARGET_PLAYBOOK}" ]; then
  echo -e "${green} TARGET_PLAYBOOK is defined ${happy_smiley} : ${TARGET_PLAYBOOK} ${NC}"
else
  echo -e "${red} ${double_arrow} Undefined build parameter ${head_skull} : TARGET_PLAYBOOK, use the default one ${NC}"
  export TARGET_PLAYBOOK=jenkins-full.yml
  echo -e "${magenta} TARGET_PLAYBOOK : ${TARGET_PLAYBOOK} ${NC}"
fi

if [ -n "${DRY_RUN}" ]; then
  echo -e "${green} DRY_RUN is defined ${happy_smiley} : ${DRY_RUN} ${NC}"
else
  echo -e "${red} ${double_arrow} Undefined build parameter ${head_skull} : DRY_RUN, use the default one ${NC}"
  export DRY_RUN="--check"
  echo -e "${magenta} DRY_RUN : ${DRY_RUN} ${NC}"
fi

if [ -n "${DOCKER_RUN}" ]; then
  echo -e "${green} DOCKER_RUN is defined ${happy_smiley} : ${DOCKER_RUN} ${NC}"
else
  echo -e "${red} ${double_arrow} Undefined build parameter ${head_skull} : DOCKER_RUN, use the default one ${NC}"
  export DOCKER_RUN=""
  echo -e "${magenta} DOCKER_RUN : ${DOCKER_RUN} ${NC}"
fi

if [ -n "${ANSIBLE_INVENTORY}" ]; then
  echo -e "${green} ANSIBLE_INVENTORY is defined ${happy_smiley} : ${ANSIBLE_INVENTORY} ${NC}"
else
  echo -e "${red} ${double_arrow} Undefined build parameter ${head_skull} : ANSIBLE_INVENTORY, use the default one ${NC}"
  export ANSIBLE_INVENTORY="inventory/production"
  echo -e "${magenta} ANSIBLE_INVENTORY : ${ANSIBLE_INVENTORY} ${NC}"
fi

if [ -n "${ANSIBLE_INVENTORY_OUTPUT_DIR}" ]; then
  echo -e "${green} ANSIBLE_INVENTORY_OUTPUT_DIR is defined ${happy_smiley} : ${ANSIBLE_INVENTORY_OUTPUT_DIR} ${NC}"
else
  echo -e "${red} ${double_arrow} Undefined build parameter ${head_skull} : ANSIBLE_INVENTORY_OUTPUT_DIR, use the default one ${NC}"
  export ANSIBLE_INVENTORY_OUTPUT_DIR="target/" # default is ~/.ansible.log
  echo -e "${magenta} ANSIBLE_INVENTORY_OUTPUT_DIR : ${ANSIBLE_INVENTORY_OUTPUT_DIR} ${NC}"
fi

if [ -n "${JUNIT_OUTPUT_DIR}" ]; then
  echo -e "${green} JUNIT_OUTPUT_DIR is defined ${happy_smiley} : ${JUNIT_OUTPUT_DIR} ${NC}"
else
  echo -e "${red} ${double_arrow} Undefined build parameter ${head_skull} : JUNIT_OUTPUT_DIR, use the default one ${NC}"
  export JUNIT_OUTPUT_DIR="target"
  echo -e "${magenta} JUNIT_OUTPUT_DIR : ${JUNIT_OUTPUT_DIR} ${NC}"
fi

if [ -n "${VIRTUAL_ENV}" ]; then
  echo -e "${green} VIRTUAL_ENV is defined ${happy_smiley} : ${VIRTUAL_ENV} ${NC}"
else
  echo -e "${red} ${double_arrow} Undefined build parameter ${head_skull} ${NC}"
  #export VIRTUAL_ENV="/opt/ansible/env38"
  #echo -e "${magenta} VIRTUAL_ENV : ${VIRTUAL_ENV} ${NC}"
fi
if [ -n "${ANSIBLE_CMD}" ]; then
  echo -e "${green} ANSIBLE_CMD is defined ${happy_smiley} : ${ANSIBLE_CMD} ${NC}"
else
  echo -e "${red} ${double_arrow} Undefined build parameter ${head_skull} : ANSIBLE_CMD, use the default one ${NC}"
  # if virtualenv is not used and there is system installation
  # of python3, it should be used
  ANSIBLE_CMD="ansible"
  if [[ -z $VIRTUAL_ENV ]]
  then
    #/usr/bin/ansible for RedHat
    #/usr/local/bin/ansible for Ubuntu
    echo "No VIRTUAL_ENV"
    if [ "${OS}" == "Ubuntu" ]; then
      if [ $(float_gt ${VER} 20) == 1 ]; then
        echo " VER : $VER gt"
        #ANSIBLE_CMD="${HOME}/.local/bin/ansible"
      else
        echo " VER : $VER lt"
        #ANSIBLE_CMD="/usr/local/bin/ansible"
      fi
    else
      ANSIBLE_CMD="/usr/bin/ansible"
    fi
  else
    if [ "${OS}" == "Ubuntu" ]; then
      if [ $(float_gt ${VER} 20) == 1 ]; then
        echo " VER : $VER gt"
        #ANSIBLE_CMD="${PYTHON_CMD} ${HOME}/.local/bin/ansible"
      else
        echo " VER : $VER lt"
        #ANSIBLE_CMD="${PYTHON_CMD} /usr/local/bin/ansible"
      fi
    else
      ANSIBLE_CMD="${PYTHON_CMD} /usr/bin/ansible"
    fi
  fi
  export ANSIBLE_CMD
  echo -e "${magenta} ANSIBLE_CMD : ${ANSIBLE_CMD} ${NC}"
fi

if [ -n "${ANSIBLE_CMBD_CMD}" ]; then
  echo -e "${green} ANSIBLE_CMBD_CMD is defined ${happy_smiley} : ${ANSIBLE_CMBD_CMD} ${NC}"
else
  echo -e "${red} ${double_arrow} Undefined build parameter ${head_skull} : ANSIBLE_CMBD_CMD, use the default one ${NC}"

  #/usr/bin/ansible-cmdb for RedHat
  #/usr/local/bin/ansible-cmdb for Ubuntu
  ANSIBLE_CMBD_CMD="ansible-cmdb"
  if [ "${OS}" == "Ubuntu" ]; then
    if [ $(float_gt ${VER} 20) == 1 ]; then
      echo " VER : $VER gt"
      ANSIBLE_CMBD_CMD="${HOME}/.local/bin/ansible-cmdb"
    else
      echo " VER : $VER lt"
      #ANSIBLE_CMBD_CMD="/usr/local/bin/ansible-cmdb"
    fi
  else
    ANSIBLE_CMBD_CMD="/usr/bin/ansible-cmdb"
  fi
  export ANSIBLE_CMBD_CMD
  echo -e "${magenta} ANSIBLE_CMBD_CMD : ${ANSIBLE_CMBD_CMD} ${NC}"
fi

if [ -n "${ANSIBLE_GALAXY_CMD}" ]; then
  echo -e "${green} ANSIBLE_GALAXY_CMD is defined ${happy_smiley} : ${ANSIBLE_GALAXY_CMD} ${NC}"
else
  echo -e "${red} ${double_arrow} Undefined build parameter ${head_skull} : ANSIBLE_GALAXY_CMD, use the default one ${NC}"
  # if virtualenv is not used and there is system installation
  # of python3, it should be used
  ANSIBLE_GALAXY_CMD="ansible-galaxy"
  if [[ -z $VIRTUAL_ENV ]]
  then
    #/usr/bin/ansible-galaxy for RedHat
    #/usr/local/bin/ansible-galaxy for Ubuntu
    if [ "${OS}" == "Ubuntu" ]; then
      if [ $(float_gt ${VER} 20) == 1 ]; then
        echo " VER : $VER gt"
        #ANSIBLE_GALAXY_CMD="${HOME}/.local/bin/ansible-galaxy"
      else
        echo " VER : $VER lt"
        #ANSIBLE_GALAXY_CMD="/usr/local/bin/ansible-galaxy"
      fi
    else
      ANSIBLE_GALAXY_CMD="/usr/bin/ansible-galaxy"
    fi
  else
    if [ "${OS}" == "Ubuntu" ]; then
      if [ $(float_gt ${VER} 20) == 1 ]; then
        echo " VER : $VER gt"
        #ANSIBLE_GALAXY_CMD="${PYTHON_CMD} ${HOME}/.local/bin/ansible-galaxy"
      else
        echo " VER : $VER lt"
        ANSIBLE_GALAXY_CMD="${PYTHON_CMD} /usr/local/bin/ansible-galaxy"
      fi
    else
      ANSIBLE_GALAXY_CMD="${PYTHON_CMD} /usr/bin/ansible-galaxy"
    fi
  fi
  export ANSIBLE_GALAXY_CMD
  echo -e "${magenta} ANSIBLE_GALAXY_CMD : ${ANSIBLE_GALAXY_CMD} ${NC}"
fi

if [ -n "${ANSIBLE_PLAYBOOK_CMD}" ]; then
  echo -e "${green} ANSIBLE_PLAYBOOK_CMD is defined ${happy_smiley} : ${ANSIBLE_PLAYBOOK_CMD} ${NC}"
else
  echo -e "${red} ${double_arrow} Undefined build parameter ${head_skull} : ANSIBLE_PLAYBOOK_CMD, use the default one ${NC}"
  # if virtualenv is not used and there is system installation
  # of python3, it should be used
  ANSIBLE_PLAYBOOK_CMD="ansible-playbook"
  if [[ -z $VIRTUAL_ENV ]]
  then
    #/usr/bin/ansible-playbook for RedHat
    #/usr/local/bin/ansible-playbook for Ubuntu
    if [ "${OS}" == "Ubuntu" ]; then
      if [ $(float_gt ${VER} 20) == 1 ]; then
        echo " VER : $VER gt"
        #ANSIBLE_PLAYBOOK_CMD="${HOME}/.local/bin/ansible-playbook"
      else
        echo " VER : $VER lt"
        #ANSIBLE_PLAYBOOK_CMD="/usr/local/bin/ansible-playbook"
      fi
    else
      ANSIBLE_PLAYBOOK_CMD="/usr/bin/ansible-playbook"
    fi
  else
    if [ "${OS}" == "Ubuntu" ]; then
      if [ $(float_gt ${VER} 20) == 1 ]; then
        echo " VER : $VER gt"
        ANSIBLE_PLAYBOOK_CMD="${PYTHON_CMD} ${HOME}/.local/bin/ansible-playbook"
      else
        echo " VER : $VER lt"
        ANSIBLE_PLAYBOOK_CMD="${PYTHON_CMD} /usr/local/bin/ansible-playbook"
      fi
    else
      ANSIBLE_PLAYBOOK_CMD="${PYTHON_CMD} /usr/bin/ansible-playbook"
    fi
  fi
  export ANSIBLE_PLAYBOOK_CMD
  echo -e "${magenta} ANSIBLE_PLAYBOOK_CMD : ${ANSIBLE_PLAYBOOK_CMD} ${NC}"
fi

if [ -n "${ANSIBLE_LINT_CMD}" ]; then
  echo -e "${green} ANSIBLE_LINT_CMD is defined ${happy_smiley} : ${ANSIBLE_LINT_CMD} ${NC}"
else
  echo -e "${red} ${double_arrow} Undefined build parameter ${head_skull} : ANSIBLE_LINT_CMD, use the default one ${NC}"
  # if virtualenv is not used and there is system installation
  # of python3, it should be used
  ANSIBLE_LINT_CMD="ansible-lint"
  if [[ -z $VIRTUAL_ENV ]]
  then
    #/usr/bin/ansible-lint for RedHat
    #/usr/local/bin/ansible-lint for Ubuntu
    if [ "${OS}" == "Ubuntu" ]; then
      if [ $(float_gt ${VER} 20) == 1 ]; then
        echo " VER : $VER gt"
        #ANSIBLE_LINT_CMD="${HOME}/.local/bin/ansible-lint"
      else
        echo " VER : $VER lt"
        ANSIBLE_LINT_CMD="/usr/local/bin/ansible-lint"
      fi
    else
      ANSIBLE_LINT_CMD="/usr/bin/ansible-lint"
    fi
  else
    if [ "${OS}" == "Ubuntu" ]; then
      if [ $(float_gt ${VER} 20) == 1 ]; then
        echo " VER : $VER gt"
        #ANSIBLE_LINT_CMD="${PYTHON_CMD} ${HOME}/.local/bin/ansible-lint"
      else
        echo " VER : $VER lt"
        ANSIBLE_LINT_CMD="${PYTHON_CMD} /usr/local/bin/ansible-lint"
      fi
    else
      ANSIBLE_LINT_CMD="${PYTHON_CMD} /usr/bin/ansible-lint"
    fi
  fi
  export ANSIBLE_LINT_CMD
  echo -e "${magenta} ANSIBLE_LINT_CMD : ${ANSIBLE_LINT_CMD} ${NC}"
fi
