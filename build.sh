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
DOCKERREGISTRY=""
DOCKERORGANISATION=""
DOCKERUSERNAME="nabla"
DOCKERNAME="ansible-jenkins-slave-docker"
#DOCKERTAG="ubuntu:16.04"
DOCKERTAG="latest"

echo -e "${green} Insalling roles version ${NC}"
ansible-galaxy install -r requirements.yml -p ./roles/ --ignore-errors

echo -e "${green} Building docker image ${NC}"
time docker build -f Dockerfile-jenkins-slave-ubuntu:16.04 -t "$DOCKERNAME" . --no-cache --tag "$DOCKERTAG"
RC=$?
if [ ${RC} -ne 0 ]; then
  echo ""
  echo -e "${red} ${head_skull} Sorry, build failed. ${NC}"
  exit 1
else
  echo -e "${green} The build completed successfully. ${NC}"
fi

echo -e ""
echo -e "${green} This image is a trusted docker hub Image. ${happy_smiley} ${NC}"
echo -e "See https://hub.docker.com/r/nabla/ansible-jenkins-slave-docker/"
echo -e ""
echo -e "To push it"
echo -e "    docker login ${DOCKERREGISTRY} --username $DOCKERUSERNAME --password password"
echo -e "    docker tag $DOCKERNAME:latest $DOCKERREGISTRY/$DOCKERORGANISATION/$DOCKERNAME:latest"
echo -e "    docker push $DOCKERREGISTRY/$DOCKERORGANISATION/$DOCKERNAME"
echo -e ""
echo -e "To pull it"
echo -e "    docker pull $DOCKERREGISTRY/$DOCKERORGANISATION/$DOCKERNAME:$DOCKERTAG"
echo -e ""
echo -e "To use this docker:"
echo -e "    docker run -d -P $DOCKERNAME"
echo -e " - to attach your container directly to the host's network interfaces"
echo -e "    docker run --net host -d -P $DOCKERNAME"
echo -e ""
echo -e "To run in interactive mode for debug:"
echo -e "    docker run -t -i $DOCKERNAME bash"
echo -e ""

exit 0
