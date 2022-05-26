# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

# Table of contents

// spell-checker:disable

<!-- toc -->

  * [Size 🌈](#size-%F0%9F%8C%88)
- [[Unreleased]](#unreleased)
- [[2.0.2] - TODO](#202---todo)
- [[2.0.1] - 2021-13-01](#201---2021-13-01)
  * [Added](#added)
  * [Updated](#updated)
- [[2.0.0] - 13-12-2021](#200---13-12-2021)
  * [Updated](#updated-1)
  * [Remove](#remove)
- [[1.0.19] - TODO](#1019---todo)
- [[1.0.18] - 2021-13-01](#1018---2021-13-01)
  * [Added](#added-1)
  * [Updated](#updated-2)
- [[1.0.17] - 2021-12-03](#1017---2021-12-03)
  * [Added](#added-2)
- [[1.0.13] - 2020-06-01](#1013---2020-06-01)
  * [Added](#added-3)
  * [Updated](#updated-3)
  * [Added](#added-4)
- [[1.0.0] - 2020-01-01](#100---2020-01-01)
  * [Added](#added-5)
  * [Updated](#updated-4)
  * [Remove](#remove-1)

<!-- tocstop -->

// spell-checker:enable

### Size 🌈

// cSpell:words linuxbrew skaffold chromedriver kubectl
- .linuxbrew = 761 + 86 + 58 MB
- .cache/Homebrew = 84 MB + 41 MB + 38 MB
- node = 60 MB
- .npm = 38 + 18 + 15 + 15 MB
- skaffold = 48 MB
- kubectl = 44 MB
- java 8 = 131 + 27 MB
- draft = 14 MB
- helm 13 MB
- chromedriver 12 MB

## [Unreleased]

<!--lint disable no-undefined-references-->

## [2.0.3] - TODO

## [2.0.2] - 2022-26-05

### Added

- Add go language

### Updated

- Nodejs 16 npm 8.5.0
- Chromedriver to 98.0.4758.102

### Removed

- Draft

## [2.0.1] - 2021-13-01

### Added

- Add github action

### Updated

- Add linter mega-linter, cspell

## [2.0.0] - 13-12-2021

Ubuntu 20.04

`docker pull nabla/ansible-jenkins-slave-docker:2.0.0`

### Updated
- node v14.16.1
- npm to 7.11.2
- helm 3.5.4 an plugin version hard coded

### Remove
// cSpell:words flashplugin flashplayer
- adobe-flashplugin (remove flashplayer support)

## [1.0.19] - TODO

## [1.0.18] - 2021-13-01

### Added

- Add github action

### Updated

- Add linter mega-linter, cspell

## [1.0.17] - 2021-12-03

Ubuntu 18.04

### Added
- Squash image

## [1.0.13] - 2020-06-01

I strongly advice you to move to helm 3

### Added
- Support python 3.8 on Ubuntu 20

### Updated
- helm v3.2.1
- kubernetes v1.18.3
- Maven 3.6.3
- Add jenkins agent [docker-agent](https://github.com/jenkinsci/docker-agent)
- gcc 7 is the minimum for Ubuntu 19
- gcc 9.3.0 is the default for Ubuntu 20
- gcc 9 is the default for Ubuntu 19
- gcc 7 is the default for Ubuntu 18
- gcc 4.8 is still available on Ubuntu 18
- gcc 4.8 is no more available on Ubuntu 19
- gcc_version: "=4:9.2.1-3.1ubuntu1" # g++ 9 on ubuntu 19
- gcc_version: "=4:7.4.0-1ubuntu2.3" # g++ 7 on ubuntu 18

### Added

<!--lint disable no-undefined-references-->
## [1.0.0] - 2020-01-01

I strongly advice you to move to python 3.7.5

### Added
- kubernetes 1.17.2
- helm 2.14.3
// cSpell:words hadolint dockerfilelint
- Docker linter : [hadolint](https://github.com/hadolint/hadolint), [dockerfilelint](https://hub.docker.com/r/replicated/dockerfilelint/), [dive](https://github.com/wagoodman/dive)
- Support python 3.7 on Ubuntu 19
- Support on Ubuntu 19 and 18 (patch only), but no more Ubuntu 16
- Support kubernetes, helm
- Add RedHat subscription to vault
- Fix permissions on .ssh folder (WARNING this allow jenkins user to connect as root to all other servers)

### Updated
- Ubuntu 18.04
- pip to 20.0.1
// cSpell:words setuptools
- python 3.6 fix setuptools==41.0.0 # See <https://github.com/ansible/molecule/issues/2350>
- python3 default is python 3.7.6
- pip 2 and 3.7 to 20.0.1 pip 3.6 to 20.0.1
- java updated to openjdk version "1.8.0_232"
- docker version 19.03.5
- node 11.12.0
- npm 6.13.6
- gcc 5.4.0
- java 1.8.0_161
- maven 3.5.0
- python 3.5.2 virtualenv /opt/ansible/env35 (no 3.6 and 3.7)
- ansible 2.7.14
- Image reduced from 4.53 GB to 3.5GB (1.0.22 Dockerfile-light 3.12 GB)
  Fix dive threshold highestUserWastedPercent

dive report
`
  efficiency: 93.4520 %

  wastedBytes: 885950854 bytes (886 MB)

  userWastedPercent: 10.3672 %
`

- ubuntu 16.04 -> ansible==2.7.14
- ubuntu 18.04 -> ansible==2.7.14 (2.8.6 and 2.8.8 are buggy)
- ubuntu 19.04 -> ansible===2.9.1

### Remove
- Python 3.6.9 will no more be supported on Ubuntu 19, Even if you install it by hand. because of [sqlite3](https://github.com/gunthercox/chatterbot-corpus/issues/116)
- Remove Ubuntu 16 support and below
- Drop support python 3.5. (at all)
- Drop support oracle JDK. Only open JDK 8 and above
- Drop support gcc below than 4.8.5
// cSpell:words gnustep
- Drop support for objective C and gnustep on docker image (too big)
- Drop support for CentOS/RedHat 5 and below and Solaris
- Drop support for node/npm below 10.15.2/6.13.6
- Drop support for docker below 19.03.3
- Drop support for ansible below 2.7.9

`docker run -it -u 1004:999 -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro -v /var/run/docker.sock:/var/run/docker.sock --entrypoint /bin/bash registry.hub.docker.com/nabla/ansible-jenkins-slave:1.0.0`
