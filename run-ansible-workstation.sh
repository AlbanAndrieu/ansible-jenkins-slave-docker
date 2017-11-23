#!/bin/bash
#set -xve

bold="\033[01m"
underline="\033[04m"
blink="\033[05m"

black="\033[30m"
red="\033[31m"
green="\033[32m"
yellow="\033[33m"
blue="\033[34m"
magenta="\033[35m"
cyan="\033[36m"
ltgray="\033[37m"

NC="\033[0m"

#double_arrow='\u00BB'
double_arrow='\xC2\xBB'
#head_skull='\u2620'
head_skull='\xE2\x98\xA0'
#happy_smiley='\u263A'
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

if [ -n "${DOCKER_RUN}" ]; then
  echo -e "${green} DOCKER_RUN is defined ${happy_smiley} ${NC}"
else
  echo -e "${red} \u00BB Undefined build parameter ${head_skull} : DOCKER_RUN, use the default one ${NC}"
  export DOCKER_RUN=""
fi

if [ -n "${ANSIBLE_CMD}" ]; then
  echo -e "${green} ANSIBLE_CMD is defined ${happy_smiley} ${NC}"
else
  echo -e "${red} \u00BB Undefined build parameter ${head_skull} : ANSIBLE_CMD, use the default one ${NC}"
  export ANSIBLE_CMD="/usr/local/bin/ansible"
fi

if [ -n "${ANSIBLE_CMBD_CMD}" ]; then
  echo -e "${green} ANSIBLE_CMBD_CMD is defined ${happy_smiley} ${NC}"
else
  echo -e "${red} \u00BB Undefined build parameter ${head_skull} : ANSIBLE_CMBD_CMD, use the default one ${NC}"
  export ANSIBLE_CMBD_CMD="/usr/local/bin/ansible-cmdb"
fi

if [ -n "${ANSIBLE_GALAXY_CMD}" ]; then
  echo -e "${green} ANSIBLE_GALAXY_CMD is defined ${happy_smiley} ${NC}"
else
  echo -e "${red} \u00BB Undefined build parameter ${head_skull} : ANSIBLE_GALAXY_CMD, use the default one ${NC}"
  export ANSIBLE_GALAXY_CMD="/usr/local/bin/ansible-galaxy"
fi

if [ -n "${ANSIBLE_PLAYBOOK_CMD}" ]; then
  echo -e "${green} ANSIBLE_PLAYBOOK_CMD is defined ${happy_smiley} ${NC}"
else
  echo -e "${red} \u00BB Undefined build parameter ${head_skull} : ANSIBLE_PLAYBOOK_CMD, use the default one ${NC}"
  export ANSIBLE_PLAYBOOK_CMD="/usr/local/bin/ansible-playbook"
fi

lsb_release -a

echo -e " ======= Running on ${TARGET_SLAVE} ${reverse_exclamation} ${NC}"
echo "USER : $USER"
echo "HOME : $HOME"
echo "WORKSPACE : $WORKSPACE"

#export ANSIBLE_DEBUG=1

echo -e "${red} Configure workstation ${NC}"

#todo use virtualenv

#echo "Switch to python 2.7 and ansible 2.1.1"
#scl enable python27 bash
#Enable python 2.7 and switch to ansible 2.1.1
#source /opt/rh/python27/enable

echo -e "${cyan} =========== ${NC}"
echo -e "${green} Checking version ${NC}"

python --version
pip --version
${ANSIBLE_CMD} --version
${ANSIBLE_GALAXY_CMD} --version

#vagrant --version
#docker --version

cd "${WORKSPACE}/env/scripts/jenkins"

echo -e "${cyan} =========== ${NC}"
echo -e "${green} Insalling roles version ${NC}"
${ANSIBLE_GALAXY_CMD} install -r requirements.yml -p ./roles/ --ignore-errors --force

echo -e "${cyan} =========== ${NC}"
echo -e "${green} Display setup ${NC}"
${ANSIBLE_CMD} -m setup ${TARGET_SLAVE} -i staging -vvvv

# check quality
#ansible-lint ${TARGET_PLAYBOOK}

# check syntax
echo -e "${cyan} =========== ${NC}"
echo -e "${green} Starting the syntax-check. ${NC}"
${ANSIBLE_PLAYBOOK_CMD} -i staging -c local -v ${TARGET_PLAYBOOK} --limit ${TARGET_SLAVE} ${DRY_RUN} -vvvv --syntax-check --become-method=sudo
RC=$?
if [ ${RC} -ne 0 ]; then
  echo ""
  echo -e "${red} ${head_skull} Sorry, syntax-check failed ${NC}"
  #exit 1
else
  echo -e "${green} The syntax-check completed successfully. ${NC}"
fi

cd "${WORKSPACE}/ansible"
  
# test ansible
if [ "${DOCKER_RUN}" == "" ]; then
  echo -e "${red} \u00BB Undefined build parameter ${head_skull} : DOCKER_RUN${NC}"
  ./setup.sh
else
  ./build.sh
fi

echo -e "${cyan} =========== ${NC}"
echo -e "${green} Ansible server inventory ${NC}"
rm -Rf out || true
mkdir out
#${ANSIBLE_CMD} -i staging -m setup --user=root --tree out/ all
${ANSIBLE_CMD} -i production -m setup --user=root -vvv --tree out/ all
RC=$?
if [ ${RC} -ne 0 ]; then
  echo ""
  echo -e "${red} ${head_skull} Sorry, inventory failed ${NC}"
  exit 1
else
  echo -e "${green} The inventory completed successfully. ${NC}"
fi

echo -e "${cyan} =========== ${NC}"
echo -e "${green} Ansible server inventory HTML generation ${NC}"
${ANSIBLE_CMBD_CMD} -i ./production out/ > overview.html
#sudo cp overview.html /var/www/html/
echo -e "${green} Ansible server summary done. $? ${NC}"  

echo -e "${green} See http://${TARGET_SLAVE}/overview.html ${NC}"  

cd "${WORKSPACE}/bm/Scripts/shell"

echo -e "${cyan} =========== ${NC}"
shellcheck *.sh -f checkstyle > checkstyle-result.xml || true
echo -e "${green} shell check for shell done. $? ${NC}"

echo -e "${cyan} =========== ${NC}"
cd "${WORKSPACE}/bm/Scripts/release"
shellcheck *.sh -f checkstyle > checkstyle-result.xml || true
echo -e "${green} shell check for release done. $? ${NC}"


echo -e "${cyan} =========== ${NC}"
cd "${WORKSPACE}/bm/Scripts/Python"
pylint **/*.py
echo -e "${green} pyhton check for shell done. $? ${NC}"

#pyreverse -o png -p Pyreverse pylint/pyreverse/

exit 0
