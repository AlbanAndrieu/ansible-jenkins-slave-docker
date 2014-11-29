#!/bin/sh

#create a git local repo
#touch README.md
#git init
#git add README.md
#git commit -m "first commit"
#git remote add origin https://github.com/AlbanAndrieu/ansible-swarm.git
#git push -u origin master

git clone https://github.com/AlbanAndrieu/ansible-jenkins-slave-docker.git

mkdir roles

cd roles

git submodule add https://github.com/AlbanAndrieu/ansible-subversion.git alban.andrieu.subversion

git submodule add https://github.com/AlbanAndrieu/ansible-role-git.git geerlingguy.git

git submodule add https://github.com/AlbanAndrieu/ansible-jenkins-slave.git alban.andrieu.jenkins-slave

git submodule add https://github.com/AlbanAndrieu/ansible-xvbf alban.andrieu.xvbf

git submodule add https://github.com/AlbanAndrieu/ansible-cmake alban.andrieu.cmake

#git submodule deinit -f alban.andrieu.cpp
git submodule add https://github.com/AlbanAndrieu/ansible-cpp alban.andrieu.cpp

git pull && git submodule init && git submodule update && git submodule status
#git submodule foreach git pull
git submodule foreach git checkout master

ansigenome gendoc -f md
ansigenome export -t reqs
ansigenome export -o ./test.dot -f dot -d 500
/usr/bin/dot -V
/usr/bin/dot -v
#/usr/bin/dot -Tps test.dot -o test.ps
/usr/bin/dot -Tpng test.dot > test.png

ansigenome export -o ./test.png -f png -d 500
