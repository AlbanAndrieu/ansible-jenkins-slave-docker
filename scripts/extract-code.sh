#!/bin/bash
#set -xv

WORKING_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )"

# source only if terminal supports color, otherwise use unset color vars
# shellcheck source=/dev/null
source "${WORKING_DIR}/step-0-color.sh"
#create a git local repo
#touch README.md
#git init
#git add README.md
#git commit -m "first commit"
#git remote add origin https://github.com/AlbanAndrieu/ansible-swarm.git
#git push -u origin master

echo -e "${magenta} git clone https://github.com/AlbanAndrieu/ansible-jenkins-slave-docker.git ${HOME}/ansible-jenkins-slave-docker"

#first run in ansible-nabla root
cd "${HOME}/ansible-nabla"
ansible-galaxy install -r requirements.yml -p ./roles/ --ignore-errors

git pull origin master --allow-unrelated-histories

git pull && git submodule init && git submodule update && git submodule status
#git fetch --recurse-submodules
#git submodule foreach git fetch
git submodule foreach git pull origin master
git submodule foreach git checkout master
git submodule foreach git pull origin master

mkdir roles

cd roles

git submodule add https://github.com/AlbanAndrieu/ansible-subversion.git alban.andrieu.subversion

git submodule add https://github.com/AlbanAndrieu/ansible-role-git.git geerlingguy.git

#git submodule deinit -f alban.andrieu.jenkins-slave
#rm -rf ../.git/modules/roles/alban.andrieu.jenkins-slave/
#git submodule add https://github.com/AlbanAndrieu/ansible-jenkins-slave.git alban.andrieu.jenkins-slave
ln -s /workspace/users/albandri30/alban.andrieu.jenkins-slave alban.andrieu.jenkins-slave

git submodule add https://github.com/AlbanAndrieu/ansible-xvbf alban.andrieu.xvbf

git submodule add https://github.com/AlbanAndrieu/ansible-cmake alban.andrieu.cmake

#git submodule deinit -f alban.andrieu.cpp
git submodule add https://github.com/AlbanAndrieu/ansible-cpp alban.andrieu.cpp

#git submodule deinit -f python
#git submodule add https://github.com/Stouts/Stouts.python.git python
#git submodule deinit -f geerlingguy.ntp
#git submodule add https://github.com/geerlingguy/ansible-role-ntp.git geerlingguy.ntp
#git submodule deinit -f locale
#git submodule add https://github.com/AlbanAndrieu/ansible-locale.git locale
git submodule add https://github.com/AlbanAndrieu/ansible-hostname.git alban.andrieu.hostname
git submodule add https://github.com/AlbanAndrieu/ansible-java.git java
git submodule add https://github.com/AlbanAndrieu/ansible-common.git alban.andrieu.common
git submodule add https://github.com/AlbanAndrieu/ansible-selenium.git alban.andrieu.selenium
git submodule add https://github.com/AlbanAndrieu/ansible-role-maven.git maven
git submodule add https://github.com/AlbanAndrieu/devbox.chrome.git chrome
#git submodule deinit -f nodejs
#git submodule add https://github.com/AlbanAndrieu/ansible-nodejs.git nodejs
git submodule add https://github.com/AlbanAndrieu/ansible-tomcat.git alban.andrieu.tomcat

git submodule add https://github.com/AlbanAndrieu/ansible-jboss.git alban.andrieu.jboss

git pull && git submodule init && git submodule update && git submodule status
git submodule foreach git checkout master
git submodule foreach git pull

ansigenome gendoc -f md
ansigenome export -t reqs
ansigenome export -o ./test.dot -f dot -d 500
/usr/bin/dot -V
/usr/bin/dot -v
#/usr/bin/dot -Tps test.dot -o test.ps
/usr/bin/dot -Tpng test.dot > test.png

ansigenome export -o ./test.png -f png -d 500
