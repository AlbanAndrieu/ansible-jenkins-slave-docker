## [![Nabla](http://albandrieu.com/nabla/index/assets/nabla/nabla-4.png)](https://github.com/AlbanAndrieu) Jenkins slave Docker image

[![License](http://img.shields.io/:license-apache-blue.svg?style=flat-square)](http://www.apache.org/licenses/LICENSE-2.0.html)
[![Travis CI](https://img.shields.io/travis/AlbanAndrieu/ansible-jenkins-slave-docker.svg?style=flat)](https://travis-ci.org/AlbanAndrieu/ansible-jenkins-slave-docker)
[![Branch](http://img.shields.io/github/tag/AlbanAndrieu/ansible-jenkins-slave-docker.svg?style=flat-square)](https://github.com/AlbanAndrieu/ansible-jenkins-slave-docker/tree/master)
[![Ansible Galaxy](https://img.shields.io/badge/galaxy-alban.andrieu.eclipse-660198.svg?style=flat)](https://galaxy.ansible.com/AlbanAndrieu/ansible-jenkins-slave-docker)
[![Platforms](http://img.shields.io/badge/platforms-el%20/%20macosx%20/%20ubuntu-lightgrey.svg?style=flat)]()
[![Docker Pulls](https://img.shields.io/docker/pulls/nabla/ansible-jenkins-slave-docker)](https://hub.docker.com/r/nabla/ansible-jenkins-slave-docker)<br/>

# Table of contents

<!-- toc -->

- [Requirements](#requirements)
    + [python 3.8](#python-38)
    + [pre-commit](#pre-commit)
    + [npm-groovy-lint groovy formating for Jenkinsfile](#npm-groovy-lint-groovy-formating-for-jenkinsfile)
- [Usage](#usage)
    + [Linting](#linting)
    + [Ideas for improvement](#ideas-for-improvement)
  * [Folder Structure Conventions](#folder-structure-conventions)
    + [A typical top-level directory layout](#a-typical-top-level-directory-layout)
  * [Update README.md](#update-readmemd)
    + [Contributing](#contributing)
    + [Authors and license](#authors-and-license)
  * [License](#license)
    + [Feedback, bug-reports, requests, ...](#feedback-bug-reports-requests-)
  * [Contact](#contact)

<!-- tocstop -->

# Requirements

- Requires Ansible 2.9.4 or newer
- Expects Ubuntu

This playbook deploy a very basic jenkins slave with all the required tool needed for a developper or buildmaster or devops to work on NABLA projects.
This playbook is be used by [Docker Hub][3] to create a [Docker][1] image.

Goal of this project is to integrate of several roles done by the community.
Goal is to contribuate to the community as much as possible instead of creating a new role.
Goal is to ensure following roles (GIT submodules) to work in harmony.

### python 3.8

Install python 3.8 and virtualenv

`virtualenv --no-site-packages /opt/ansible/env38 -p python3.8`

`source /opt/ansible/env38/bin/activate`

`pip install -r requirements-current-3.8.txt`

### pre-commit

See [pre-commit](http://pre-commit.com/)
Run `pre-commit install`

First time run `cp hooks/hooks/* .git/hooks/`
or `git clone git@github.com:AlbanAndrieu/nabla-hooks.git hooks && rm -Rf ./.git/hooks && ln -s ../hooks/hooks ./.git/hooks`

Run `pre-commit run --all-files`

Run `SKIP=ansible-lint git commit -am 'Add key'`
Run `git commit -am 'Add key' --no-verify`

### npm-groovy-lint groovy formating for Jenkinsfile

Tested with nodejs 12 and 16 on ubuntu 20 and 21 (not working with nodejs 11 and 16)

```
npm install -g npm-groovy-lint@8.2.0
npm-groovy-lint --format
ls -lrta .groovylintrc.json
```

# Usage

Run the playbook, like this:

    ansible-playbook -i hosts -c local -v jenkins-slave-docker.yml -vvvv
    or
    setup.sh

Create the docker hub image, like this:

    docker build -f docker/ubuntu18/Dockerfile -t "nabla/ansible-jenkins-slave-docker" . --no-cache --tag "latest"
    or
    ./scripts/docker-build.sh

Run Jenkins See https://github.com/jenkinsci/parallel-test-executor-plugin/tree/master/demo

    docker volume create --name=m2repo
    sudo chmod a+rw $(docker volume inspect -f '{{.Mountpoint}}' m2repo)
    docker run --rm -p 127.0.0.1:8080:8080 -v m2repo:/m2repo -v /var/run/docker.sock:/var/run/docker.sock --group-add=$(stat -c %g /var/run/docker.sock) -ti jenkinsci/parallel-test-executor-demo

Use the docker hub image, like this:

    #Pull image
    docker pull nabla/ansible-jenkins-slave-docker

    #Start container
    docker run -ti -d -w /sandbox/project-to-build -v /workspace/users/albandri30/:/sandbox/project-to-build:rw --name sandbox nabla/ansible-jenkins-slave-docker:latest cat
    #Build
    docker exec sandbox /opt/maven/apache-maven-3.5.0/bin/mvn -B -Djava.io.tmpdir=./tmp -Dmaven.repo.local=/home/jenkins/.m2/.repository -Dmaven.test.failure.ignore=true -s /home/jenkins/.m2/settings.xml -f nabla-servers-bower-sample/pom.xml clean install

    #Stop & remove container
    docker stop sandbox
    docker rm sandbox

When the playbook run completes, you should be able to build and test any NABLA projects, on the using the docker image in Jenkins with [Jenkins Docker plugin][2].

This is a very simple playbook and could serve as a starting point for more complex projects.

### Linting

```
ansible-lint -v playbooks/*.yml
```

[vault](https://github.com/ansible/ansible-lint/pull/991)

### Ideas for improvement

Here are some ideas for ways that these playbooks could be extended:

- Feel free to ask.

We would love to see contributions and improvements, so please fork this
repository and send us your changes via pull requests.

[1]: http://docker.io
[2]: https://wiki.jenkins-ci.org/display/JENKINS/Docker+Plugin
[3]: https://hub.docker.com

## Folder Structure Conventions

> Folder structure options and naming conventions for software projects

### A typical top-level directory layout

    .
    ├── docs                    # Documentation files (alternatively `doc`)
    docker                      # Where to put image Dockerfile
    ├── scripts                 # Source files
    ├── inventory
    │   production
    ├── playbooks               # Ansible playbooks
    ├── roles                   # Ansible roles
    bower.json                  # Bower not build directly, using maven instead
    Dockerfile                  # A link to default Dockerfile to build (DockerHub)
    Jenkinsfile
    package.json                # Nnpm not build directly, using maven instead
    pom.xml                     # Will run maven clean install
    .pre-commit-config.yaml
    requirements.testing.txt    # Python package used for test and build only
    requirements.txt            # Python package used for production only
    requirements.yml            # Ansible requirements, will be add to roles directory
    tox.ini
    sonar-project.properties    # Will run sonar standalone scan
    LICENSE
    CHANGELOG.md
    README.md
    └── target                  # Compiled files (alternatively `dist`) for maven

    docker directory is used only to build project
    .
    ├── ...
    ├── docker                  # Docker files used to build project
    │   ├── centos7             # End-to-end, integration tests (alternatively `e2e`)
    │   ├── ubuntu18            # End-to-end, integration tests (alternatively `e2e`)
    │   └── ubuntu20
    │       Dockerfile          # File to build
    │       config.yaml         # File to run CST
    └── ...

    .
    ├── ...
    ├── docs                    # Documentation files
    │   ├── index.rst           # Table of contents
    │   ├── faq.rst             # Frequently asked questions
    │   ├── misc.rst            # Miscellaneous information
    │   ├── usage.rst           # Getting started guide
    │   └── ...                 # etc.
    └── ...

    .
    ├── ...
    ├── packs                    # Files used to build docker image and chart
    │   config.yaml              # File to run CST
    │   Dockerfile               # File to build docker image
    │   └── jenkins-slave        # Name of the helm chart
    │       └── charts
    │           Chart.yaml
    │           README.md
    │           └── templates
    │               deployment.yaml
    │               helpers.tpl
    │               └── tests
    │                   test-connection.yaml
    │           values.yaml

## Update README.md


  * [github-markdown-toc](https://github.com/jonschlinkert/markdown-toc)
  * With [github-markdown-toc](https://github.com/Lucas-C/pre-commit-hooks-nodejs)

```
npm install --save markdown-toc
markdown-toc README.md
markdown-toc CHANGELOG.md  -i
```

```
git add README.md
pre-commit run markdown-toc
```

### Contributing

The [issue tracker](https://github.com/AlbanAndrieu/ansible-jenkins-slave-docker/issues) is the preferred channel for bug reports, features requests and submitting pull requests.

For pull requests, editor preferences are available in the [editor config](.editorconfig) for easy use in common text editors. Read more and download plugins at <http://editorconfig.org>.

In lieu of a formal styleguide, take care to maintain the existing coding style. Add unit tests and examples for any new or changed functionality.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

### Authors and license

`roles/alban_andrieu_jenkins_slave` role was written by:

- [Alban Andrieu](fr.linkedin.com/in/nabla/) | [e-mail](mailto:alban.andrieu@free.fr) | [Twitter](https://twitter.com/AlbanAndrieu) | [GitHub](https://github.com/AlbanAndrieu)

License
-------

- License: [GPLv3](https://tldrlegal.com/license/gnu-general-public-license-v3-%28gpl-3%29)

### Feedback, bug-reports, requests, ...

Are [welcome](https://github.com/AlbanAndrieu/ansible-jenkins-slave-docker/issues)!

***

This role is part of the [Nabla](https://github.com/AlbanAndrieu) project.
README generated by [Ansigenome](https://github.com/nickjj/ansigenome/).

***

## Contact

Alban Andrieu

[linkedin](fr.linkedin.com/in/nabla/)
