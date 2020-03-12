#!/bin/bash
#set -xve

WORKING_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )"

# source only if terminal supports color, otherwise use unset color vars
# shellcheck source=scripts/step-0-color.sh
source "${WORKING_DIR}/step-0-color.sh"

# shellcheck source=/dev/null
source "${WORKING_DIR}/step-1-os.sh"

if [ -n "${USE_SUDO}" ]; then
  echo -e "${green} USE_SUDO is defined ${happy_smiley} : ${USE_SUDO} ${NC}"
else
  echo -e "${red} ${double_arrow} Undefined build parameter ${head_skull} : USE_SUDO, use the default one ${NC}"
  if [ "${OS}" == "Ubuntu" ]; then
    USE_SUDO="sudo -H"
  else
    USE_SUDO=""
  fi
  export USE_SUDO
  echo -e "${magenta} USE_SUDO : ${USE_SUDO} ${NC}"
fi

if [ -n "${PYTHON_MAJOR_VERSION}" ]; then
  echo -e "${green} PYTHON_MAJOR_VERSION is defined ${happy_smiley} : ${PYTHON_MAJOR_VERSION} ${NC}"
  unset VIRTUALENV_PATH
  unset PYTHON_CMD
else
  echo -e "${red} ${double_arrow} Undefined build parameter ${head_skull} : PYTHON_MAJOR_VERSION, use the default one ${NC}"
  export PYTHON_MAJOR_VERSION=3.7
  echo -e "${magenta} PYTHON_MAJOR_VERSION : ${PYTHON_MAJOR_VERSION} ${NC}"
fi

if [ -n "${VIRTUALENV_PATH}" ]; then
  echo -e "${green} VIRTUALENV_PATH is defined ${happy_smiley} : ${VIRTUALENV_PATH} ${NC}"
else
  echo -e "${red} ${double_arrow} Undefined build parameter ${head_skull} : VIRTUALENV_PATH, use the default one ${NC}"
  # shellcheck disable=SC2001
  VIRTUALENV_PATH=/opt/ansible/env$(echo $PYTHON_MAJOR_VERSION | sed 's/\.//g')
  export VIRTUALENV_PATH
  echo -e "${magenta} VIRTUALENV_PATH : ${VIRTUALENV_PATH} ${NC}"
fi

if [ -n "${PYTHON_CMD}" ]; then
  echo -e "${green} PYTHON_CMD is defined ${happy_smiley} : ${PYTHON_CMD} ${NC}"
else
  echo -e "${red} ${double_arrow} Undefined build parameter ${head_skull} : PYTHON_CMD, use the default one ${NC}"
  #/usr/local/bin/python3.5 for RedHat
  #/usr/bin/python3.5 for Ubuntu
  if [ "${OS}" == "Red Hat Enterprise Linux Server" ]; then
    PYTHON_CMD="/usr/local/bin/python${PYTHON_MAJOR_VERSION}"
  else
    PYTHON_CMD="${VIRTUALENV_PATH}/bin/python${PYTHON_MAJOR_VERSION}"
    #PYTHON_CMD="/usr/bin/python3.5"
  fi
  export PYTHON_CMD
  echo -e "${magenta} PYTHON_CMD : ${PYTHON_CMD} ${NC}"
fi

echo -e "${cyan} Use virtual env ${VIRTUALENV_PATH}/bin/activate ${NC}"
#echo "Switch to python 2.7 and ansible 2.1.1"
#scl enable python27 bash
#Enable python 2.7 and switch to ansible 2.1.1
#source /opt/rh/python27/enable

#sudo virtualenv -p /usr/bin/python3.5 /opt/ansible/env35
echo -e "${green} virtualenv --no-site-packages ${VIRTUALENV_PATH} -p python${PYTHON_MAJOR_VERSION} ${NC}"
echo -e "${green} source ${VIRTUALENV_PATH}/bin/activate ${NC}"
if [ -f "${VIRTUALENV_PATH}/bin/activate" ]; then
  # shellcheck disable=SC1090
  source "${VIRTUALENV_PATH}/bin/activate" || exit 2

  #export PYTHONPATH="/usr/local/lib/python${PYTHON_MAJOR_VERSION}/dist-packages/"
  export PATH="${VIRTUALENV_PATH}/bin:${PATH}"
  echo -e "${cyan} PATH : ${PATH} ${NC}"
  export PYTHONPATH="${VIRTUALENV_PATH}/lib/python${PYTHON_MAJOR_VERSION}/site-packages/"
  echo -e "${cyan} PYTHONPATH : ${PYTHONPATH} ${NC}"
else
  echo -e "${red} Please install virtualenv first ${NC}"
fi

echo -e "${cyan} =========== ${NC}"
echo -e "${green} Display virtual env ${NC}"
virtualenv --version || true
pip -V || true
pip freeze | grep ansible || true

echo -e "${cyan} =========== ${NC}"
echo -e "${green} Install virtual env requirements prerequisites ${NC}"
echo -e "${green} sudo apt-get install libcups2-dev linuxbrew-wrapper ${NC}"
echo -e "${green} brew install cairo libxml2 libffi ${NC}"

#pip3 uninstall libxml2-python
#pip3 install cairocffi==0.8.0
#pip3 install CairoSVG==2.0.3

echo -e "${green} Fix permission rights ${NC}"
# shellcheck disable=SC2001
echo -e "${green} chown -R jenkins:docker /opt/ansible/env$(echo $PYTHON_MAJOR_VERSION | sed 's/\.//g') ${NC}"

if [ -f "${WORKING_DIR}/../playbooks/files/python/requirements-current-${PYTHON_MAJOR_VERSION}.txt" ]; then
  echo -e "${cyan} =========== ${NC}"
  echo -e "${green} Install virtual env requirements : pip install -r ${WORKING_DIR}/../playbooks/files/python/requirements-current-${PYTHON_MAJOR_VERSION}.txt ${NC}"
  #"${VIRTUALENV_PATH}/bin/pip${PYTHON_MAJOR_VERSION}" install -r "${WORKING_DIR}/../playbooks/files/python/requirements-current-${PYTHON_MAJOR_VERSION}.txt"
  "pip${PYTHON_MAJOR_VERSION}" install -r "${WORKING_DIR}/../playbooks/files/python/requirements-current-${PYTHON_MAJOR_VERSION}.txt"
  RC=$?
  if [ ${RC} -ne 0 ]; then
    echo ""
    echo -e "${red} ${head_skull} Sorry,  python requirements installation failed ${NC}"
    echo -e "${yellow} ${head_skull} WARNING : As we are using jenkins user. It might fail on purpose ${NC}"
    echo -e "${yellow} ${head_skull} because I did not want jenkins user to allow such changes ${NC}"
    exit 1
  else
    echo -e "${green} The python requirements installation completed successfully. ${NC}"
  fi
else
  echo -e "${red} Please get requirements-current-${PYTHON_MAJOR_VERSION}.txt first ${NC}"
fi

echo -e "${cyan} =========== ${NC}"
echo -e "${green} Checking docker-compose version ${NC}"

docker-compose --version
RC=$?
if [ ${RC} -ne 0 ]; then
  echo ""
  echo -e "${red} ${head_skull} Sorry, docker-compose failed ${NC}"
  "${VIRTUALENV_PATH}/bin/pip${PYTHON_MAJOR_VERSION}" freeze | grep docker

  "${VIRTUALENV_PATH}/bin/pip${PYTHON_MAJOR_VERSION}" show docker-py
  RC=$?
  if [ ${RC} -ne 1 ]; then
    echo -e "${red} ${head_skull} Please remove docker-py ${NC}"
  fi
  echo -e "${red} ${head_skull} ${VIRTUALENV_PATH}/bin/pip${PYTHON_MAJOR_VERSION} uninstall docker-py; sudo ${VIRTUALENV_PATH}/bin/pip${PYTHON_MAJOR_VERSION} uninstall docker; sudo ${VIRTUALENV_PATH}/bin/pip${PYTHON_MAJOR_VERSION} uninstall docker-compose; ${NC}"
  echo -e "${red} ${head_skull} ${VIRTUALENV_PATH}/bin/pip${PYTHON_MAJOR_VERSION} install --upgrade --force-reinstall --no-cache-dir docker-compose==1.12.0 ${NC}"
  exit 1
else
  echo -e "${green} The docker-compose check completed successfully. ${NC}"
fi

echo -e "${cyan} =========== ${NC}"
echo -e "${green} Checking python version ${NC}"

python --version || true
pip -V || true

#vagrant --version
docker version || true

#echo -e "${green} Checking python 2.7 version ${NC}"
#
#python2.7 --version || true
#pip2.7 --version || true
#
##pip2.7 show docker-py || true
#sudo -H pip2.7 list --format=legacy | grep docker || true
#
##sudo pip2.7 -H install -r requirements-current-2.7.txt
#sudo -H pip2.7 freeze > requirements-2.7.txt

echo -e "${green} Checking python ${PYTHON_MAJOR_VERSION} version ${NC}"

"python${PYTHON_MAJOR_VERSION}" --version || true
"pip${PYTHON_MAJOR_VERSION}" -V || true

python3 --version || true
pip3 --version || true

if [ -n "${PYTHON_CMD}" ]; then
  echo -e "${magenta} ${PYTHON_CMD} --version ${NC}"
  ${PYTHON_CMD} --version || true
  if [ -f "${VIRTUALENV_PATH}/bin/pip${PYTHON_MAJOR_VERSION}" ]; then
    echo -e "${magenta} ${VIRTUALENV_PATH}/bin/pip${PYTHON_MAJOR_VERSION} --version ${NC}"
    "${VIRTUALENV_PATH}/bin/pip${PYTHON_MAJOR_VERSION}" --version || true

    "${VIRTUALENV_PATH}/bin/pip${PYTHON_MAJOR_VERSION}" list --format=freeze | grep docker || true

    echo -e "${magenta} ${VIRTUALENV_PATH}/bin/pip${PYTHON_MAJOR_VERSION} freeze > requirements-${PYTHON_MAJOR_VERSION}.txt ${NC}"
    #"${VIRTUALENV_PATH}/bin/pip${PYTHON_MAJOR_VERSION}" freeze > requirements-${PYTHON_MAJOR_VERSION}.txt
  else
    echo -e "${red} Please install ${VIRTUALENV_PATH}/bin/pip${PYTHON_MAJOR_VERSION} first ${NC}"
  fi

  echo -e "${magenta} ${PYTHON_CMD} -m ara.setup.path ${NC}"
  ${PYTHON_CMD} -m ara.setup.path || true
  ${PYTHON_CMD} -m ara.setup.action_plugins || true
  ${PYTHON_CMD} -m ara.setup.callback_plugins || true
fi
