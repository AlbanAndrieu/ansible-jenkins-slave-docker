#!/bin/bash
#set -xve

#export bold="\033[01m"
#export underline="\033[04m"
#export blink="\033[05m"

#export black="\033[30m"
export red="\033[31m"
export green="\033[32m"
#export yellow="\033[33m"
#export blue="\033[34m"
export magenta="\033[35m"
export cyan="\033[36m"
#export ltgray="\033[37m"

export NC="\033[0m"

double_arrow='\xC2\xBB'
export head_skull='\xE2\x98\xA0'
export happy_smiley='\xE2\x98\xBA'
export reverse_exclamation='\u00A1'

case "$OSTYPE" in
  linux*)   SYSTEM=LINUX;;
  darwin*)  SYSTEM=OSX;;
  win*)     SYSTEM=Windows;;
  cygwin*)  SYSTEM=Cygwin;;
  msys*)    SYSTEM=MSYS;;
  bsd*)     SYSTEM=BSD;;
  solaris*) SYSTEM=SOLARIS;;
  *)        SYSTEM=UNKNOWN;;
esac
echo "SYSTEM : ${SYSTEM}"

if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
elif [ -f /etc/SuSe-release ]; then
    # Older SuSE/etc.
    ...
elif [ -f /etc/redhat-release ]; then
    # Older Red Hat, CentOS, etc.
    ...
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
fi
echo "OS : ${OS}"
echo "VER : ${VER}"

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
else
  echo -e "${red} ${double_arrow} Undefined build parameter ${head_skull} : PYTHON_MAJOR_VERSION, use the default one ${NC}"
  export PYTHON_MAJOR_VERSION=3.5
  echo -e "${magenta} PYTHON_MAJOR_VERSION : ${PYTHON_MAJOR_VERSION} ${NC}"
fi

if [ -n "${VIRTUALENV_PATH}" ]; then
  echo -e "${green} VIRTUALENV_PATH is defined ${happy_smiley} : ${VIRTUALENV_PATH} ${NC}"
else
  echo -e "${red} ${double_arrow} Undefined build parameter ${head_skull} : VIRTUALENV_PATH, use the default one ${NC}"
  VIRTUALENV_PATH=/opt/ansible/env$(echo $PYTHON_MAJOR_VERSION | sed 's/\.//g')
  echo -e "${green} virtualenv --no-site-packages ${VIRTUALENV_PATH} -p python${PYTHON_MAJOR_VERSION} ${NC}"
  echo -e "${green} source ${VIRTUALENV_PATH}/bin/activate ${NC}"
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

echo -e "${cyan} Use virtual env ${VIRTUALENV_PATH}/activate ${NC}"
#echo "Switch to python 2.7 and ansible 2.1.1"
#scl enable python27 bash
#Enable python 2.7 and switch to ansible 2.1.1
#source /opt/rh/python27/enable

#sudo virtualenv -p /usr/bin/python3.5 /opt/ansible/env35
source "${VIRTUALENV_PATH}/bin/activate" || exit 2

#export PYTHONPATH="/usr/local/lib/python${PYTHON_MAJOR_VERSION}/dist-packages/"
export PATH="${VIRTUALENV_PATH}/bin:${PATH}"
echo -e "${cyan} PATH : ${PATH} ${NC}"
export PYTHONPATH="${VIRTUALENV_PATH}/lib/python${PYTHON_MAJOR_VERSION}/site-packages/"
echo -e "${cyan} PYTHONPATH : ${PYTHONPATH} ${NC}"

echo -e "${cyan} =========== ${NC}"
echo -e "${green} Install virtual env requirements prerequisites ${NC}"
echo -e "${green} sudo apt-get install libcups2-dev linuxbrew-wrapper ${NC}"
echo -e "${green} brew install cairo libxml2 libffi ${NC}"
#source /opt/ansible/env35/bin/activate
#pip3 uninstall libxml2-python
#pip3 install cairocffi==0.8.0
#pip3 install CairoSVG==2.0.3

echo -e "${green} Fix permission rights ${NC}"
echo -e "${green} chown -R jenkins:docker /opt/ansible/env35 ${NC}"

echo -e "${cyan} =========== ${NC}"
echo -e "${green} Install virtual env requirements : pip install -r ./roles/jenkins-slave/files/requirements-current-${PYTHON_MAJOR_VERSION}.txt ${NC}"
#"${VIRTUALENV_PATH}/bin/pip${PYTHON_MAJOR_VERSION}" install -r "./roles/jenkins-slave/files/requirements-current-${PYTHON_MAJOR_VERSION}.txt"
pip install -r "./roles/jenkins-slave/files/requirements-current-${PYTHON_MAJOR_VERSION}.txt"
RC=$?
if [ ${RC} -ne 0 ]; then
  echo ""
  echo -e "${red} ${head_skull} Sorry,  python requirements installation failed ${NC}"
  exit 1
else
  echo -e "${green} The python requirements installation completed successfully. ${NC}"
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

#source ${VIRTUALENV_PATH}/bin/activate || exit 2

python --version || true
pip --version || true
virtualenv --version || true

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

echo -e "${green} Checking python 3.5 version ${NC}"

python3 --version || true
pip3 --version || true
echo -e "${magenta} ${PYTHON_CMD} --version ${NC}"
${PYTHON_CMD} --version || true
echo -e "${magenta} ${VIRTUALENV_PATH}/bin/pip${PYTHON_MAJOR_VERSION} --version ${NC}"
"${VIRTUALENV_PATH}/bin/pip${PYTHON_MAJOR_VERSION}" --version || true

"${VIRTUALENV_PATH}/bin/pip${PYTHON_MAJOR_VERSION}" list --format=freeze | grep docker || true

echo -e "${magenta} ${VIRTUALENV_PATH}/bin/pip${PYTHON_MAJOR_VERSION} freeze > requirements-${PYTHON_MAJOR_VERSION}.txt ${NC}"
"${VIRTUALENV_PATH}/bin/pip${PYTHON_MAJOR_VERSION}" freeze > requirements-${PYTHON_MAJOR_VERSION}.txt
