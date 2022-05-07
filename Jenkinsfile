#!/usr/bin/env groovy
@Library(value='jenkins-pipeline-scripts@master', changelog=false) _

String DOCKER_REGISTRY_HUB=env.DOCKER_REGISTRY_HUB ?: "index.docker.io".toLowerCase().trim()
String DOCKER_ORGANISATION="nabla".trim()
String DOCKER_TAG="1.0.10".trim()
String DOCKER_TAG_NEXT_UBUNTU_18="1.0.11".trim()
String DOCKER_NAME="ansible-jenkins-slave-docker".trim()

String DOCKER_REGISTRY_URL="https://${DOCKER_REGISTRY_HUB}".trim()
String DOCKER_REGISTRY_CREDENTIAL=env.DOCKER_REGISTRY_CREDENTIAL ?: "hub-docker-nabla".trim()
String DOCKER_IMAGE="${DOCKER_ORGANISATION}/${DOCKER_NAME}:${DOCKER_TAG}".trim()

String DOCKER_OPTS_BASIC = getDockerOpts()
String DOCKER_OPTS_COMPOSE = getDockerOpts(isDockerCompose: true, isLocalJenkinsUser: false)

containers = [:]

pipeline {
  //agent none
  agent {
    docker {
      image DOCKER_IMAGE
      alwaysPull true
      reuseNode true
      args DOCKER_OPTS_COMPOSE
      label 'molecule'
    }
  }
  parameters {
    string(name: 'DRY_RUN', defaultValue: '--check', description: 'Default mode used to test playbook')
    string(name: 'DOCKER_RUN', defaultValue: '', description: 'Default inventory used to test playbook')
    string(name: 'ANSIBLE_INVENTORY', defaultValue: 'inventory/hosts', description: 'Default inventory used to test playbook')
    string(name: 'TARGET_SLAVE', defaultValue: 'albandri', description: 'Default server used to test playbook')
    string(name: 'TARGET_PLAYBOOK', defaultValue: 'cleaning.yml', description: 'Default playbook to override')
    booleanParam(name: 'CLEAN_RUN', defaultValue: false, description: 'Clean before run')
    booleanParam(name: 'SKIP_LINT', defaultValue: false, description: 'Skip Linter - requires ansible galaxy roles, so it is time consuming')
    booleanParam(name: 'SKIP_DOCKER', defaultValue: false, description: 'Skip Docker - requires image rebuild from scratch')
    booleanParam(name: 'MOLECULE_DEBUG', defaultValue: false, description: 'Enable --debug flag for molecule - does not affect executions of other tests')
    booleanParam(defaultValue: false, description: 'Build only to have package. no test / no docker', name: 'BUILD_ONLY')
    booleanParam(defaultValue: false, description: 'Run molecule tests', name: 'BUILD_MOLECULE')
    booleanParam(defaultValue: true, description: 'Build jenkins docker images', name: 'BUILD_DOCKER')
    booleanParam(defaultValue: true, description: 'Build jenkins docker ubuntu 18 images', name: 'BUILD_DOCKER_UBUNTU18')
    booleanParam(defaultValue: true, description: 'Build jenkins docker ubuntu 20 images', name: 'BUILD_DOCKER_UBUNTU20')
    booleanParam(defaultValue: false, description: 'Build with sonar', name: 'BUILD_SONAR')
    booleanParam(defaultValue: true, description: 'Test cleaning', name: 'BUILD_CLEANING')
    booleanParam(defaultValue: false, description: 'Test cmdb', name: 'BUILD_CMDB')
    booleanParam(defaultValue: true, description: 'Run sphinx', name: 'BUILD_DOC')
  }
  //environment {
    //BRANCH_NAME = "${env.BRANCH_NAME}".replaceAll("feature/","")
    //PROJECT_BRANCH = "${env.GIT_BRANCH}".replaceFirst("origin/","")
    //BUILD_ID = "${env.BUILD_ID}"
    //DOCKER_BUILDKIT = "1" // https://github.com/moby/buildkit/issues/1004
    //COMPOSE_DOCKER_CLI_BUILD = "1"
  //}
  options {
    disableConcurrentBuilds()
    //skipStagesAfterUnstable()
    //parallelsAlwaysFailFast() // this is hidding failure and unstable stage
    ansiColor('xterm')
    timeout(time: 360, unit: 'MINUTES')
    timestamps()
  }
  stages {
    stage('Setup') {
      steps {
        script {
          setUp(description: "Ansible")

          lock("${params.TARGET_SLAVE}") {
            echo "Lock on ${params.TARGET_SLAVE} released" // we do not have many molecule label
            sh "rm -f *.log || true"
          } // lock
        }
      }
    }
    stage("Ansible pre-commit check") {
      steps {
        script {
          // TODO testPreCommit
          tee("pre-commit.log") {
            sh "#!/bin/bash \n" +
              "whoami \n" +
              "source ./scripts/run-python.sh\n" +
              "pre-commit run -a || true\n" +
              "find . -name 'kube.*' -type f -follow -exec kubectl --kubeconfig {} cluster-info \\; || true\n"
          } // tee
        } // script
      }
    } // stage pre-commit
    stage("Ansible CMDB Report") {
      when {
        expression { params.BUILD_ONLY == false && params.BUILD_CMDB == true }
      }
      steps {
        script {
          runAnsibleCmbd(shell: "./scripts/run-ansible-cmbd.sh")
        } // script
      }
    }
    stage('Documentation') {
      when {
        expression { params.BUILD_ONLY == false && params.BUILD_DOC == true }
      }
      environment {
        PYTHON_MAJOR_VERSION = "3.8"
      }
      // Creates documentation using Sphinx and publishes it on Jenkins
      // Copy of the documentation is rsynced
      steps {
        script {
          runSphinx(shell: "export PYTHON_MAJOR_VERSION=3.8 && ../scripts/run-python.sh && ./build.sh", targetDirectory: "fusionrisk-ansible/")
        }
      }
    }

    stage('Cleaning tests') {
      when {
        expression { env.BRANCH_NAME ==~ /release\/.+|master|develop|PR-.*|feature\/.*|bugfix\/.*/ }
        expression { params.BUILD_ONLY == false && params.BUILD_CLEANING == true }
      }
      steps {
        script {
          if (JENKINS_URL ==~ /.*aandrieu.*|.*albandri.*|.*test.*|.*localhost.*/ ) {
            configFileProvider([configFile(fileId: 'vault.passwd',  targetLocation: 'vault.passwd', variable: 'ANSIBLE_VAULT_PASSWORD')]) {
              ansiblePlaybook colorized: true,
                  credentialsId: 'jenkins_unix_slaves',
                  disableHostKeyChecking: true,
                  extras: '-e ansible_python_interpreter="/usr/bin/python2.7"',
                  forks: 5,
                  installation: 'ansible-latest',
                  inventory: "${params.ANSIBLE_INVENTORY}",
                  limit: "${params.TARGET_SLAVE}",
                  playbook: "${params.TARGET_PLAYBOOK}"
            } // configFileProvider

            echo "Init result: ${currentBuild.result}"
            echo "Init currentResult: ${currentBuild.currentResult}"

          } // JENKINS_URL
        } // script
      } // steps
    } // stage Cleaning tests

    stage('SonarQube analysis') {
      environment {
        SONAR_SCANNER_OPTS = "-Xmx4g"
        SONAR_USER_HOME = "$WORKSPACE"
      }
      when {
        expression { env.BRANCH_NAME ==~ /release\/.+|master|develop|PR-.*|feature\/.*|bugfix\/.*/ }
        expression { params.BUILD_ONLY == false && params.BUILD_SONAR == true }
      }
      steps {
        script {
          echo "Init result: ${currentBuild.result}"
          echo "Init currentResult: ${currentBuild.currentResult}"

          withSonarQubeWrapper(verbose: true,
            skipMaven: true,
            repository: "ansible-nabla")
        } // script
      } // steps
    } // stage SonarQube analysis
    stage('Molecule - Java') {
      when {
        expression { env.BRANCH_NAME ==~ /release\/.+|master|develop|PR-.*|feature\/.*|bugfix\/.*/ }
        expression { params.BUILD_MOLECULE == true && params.BUILD_ONLY == false }
      }
      steps {
        script {

          testAnsibleRole(roleName: "ansiblebit.oracle-java")

        } // script
      } // steps
    } // stage
    stage('Molecule') {
      when {
        expression { env.BRANCH_NAME ==~ /release\/.+|master|develop|PR-.*|feature\/.*|bugfix\/.*/ }
        expression { params.BUILD_MOLECULE == true && params.BUILD_ONLY == false }
      }
      //environment {
      //  MOLECULE_DEBUG="${params.MOLECULE_DEBUG ? '--debug' : ' '}"  // syntax: important to have the space ' '
      //}
      parallel {
        stage("administration") {
          steps {
            script {
              testAnsibleRole(roleName: "administration")
            }
          }
        }
        stage("common") {
          steps {
            script {
              testAnsibleRole(roleName: "common")
            }
          }
        }
        stage("security") {
          steps {
            script {
              testAnsibleRole(roleName: "security")
            }
          }
        }
      }
    }
    stage('Molecule parallel') {
      when {
        expression { env.BRANCH_NAME ==~ /release\/.+|master|develop|PR-.*|feature\/.*|bugfix\/.*/ }
        expression { params.BUILD_MOLECULE == true && params.BUILD_ONLY == false }
      }
      parallel {
        stage("cleaning") {
          steps {
            script {
              testAnsibleRole(roleName: "cleaning")
            }
          }
        }
        stage("DNS") {
          steps {
            script {
              testAnsibleRole(roleName: "dns")
            }
          }
        }
      }
    }
    stage('Docker') {
      parallel {
        stage('Ubuntu 18.04') {
          when {
            expression { env.BRANCH_NAME ==~ /release\/.+|master|develop|PR-.*|feature\/.*|bugfix\/.*/ }
            expression { params.BUILD_ONLY == false && params.BUILD_DOCKER == true && params.BUILD_DOCKER_UBUNTU18 == true }
          }
          steps {
            script {
              if (!params.SKIP_DOCKER) {

                echo "Init result: ${currentBuild.result}"
                echo "Init currentResult: ${currentBuild.currentResult}"

                tee('docker-build-ubuntu-18.04.log') {

                  try {

                    configFileProvider([configFile(fileId: 'vault.passwd',  targetLocation: 'vault.passwd', variable: 'ANSIBLE_VAULT_PASSWORD_FILE')]) {
                      withCredentials([string(credentialsId: 'fr-ansible-vault-password', variable: 'ANSIBLE_VAULT_PASSWORD')]) {

                        sh 'mkdir -p .ssh/ || true'

                        DOCKER_BUILD_ARGS="--pull --build-arg ANSIBLE_VAULT_PASSWORD=${ANSIBLE_VAULT_PASSWORD} "
                        DOCKER_BUILD_ARGS+= getDockerProxyOpts(isProxy: true)

                        if (isCleanRun() == true) {
                          DOCKER_BUILD_ARGS+=" --no-cache"
                        }

                        withCredentials([
                            [$class: 'UsernamePasswordMultiBinding',
                            credentialsId: DOCKER_REGISTRY_CREDENTIAL,
                            usernameVariable: 'USERNAME',
                            passwordVariable: 'PASSWORD']
                        ]) {
                          def container = docker.build("${DOCKER_REGISTRY_HUB}/${DOCKER_ORGANISATION}/${DOCKER_NAME}:${DOCKER_TAG_NEXT_UBUNTU_18_UBUNTU_18}", "${docker_build_args} -f docker/ubuntu16/Dockerfile . ")
                          container.inside {
                            sh 'echo test'
                            archiveArtifacts artifacts: '*.log, /home/jenkins/npm/cache/_logs/*-debug.log', excludes: null, fingerprint: false, onlyIfSuccessful: false
                          }

                          docker.image("${DOCKER_REGISTRY_HUB}/${DOCKER_ORGANISATION}/${DOCKER_NAME}:${DOCKER_TAG_NEXT_UBUNTU_18}").withRun("-u root --entrypoint='/entrypoint.sh'", "/bin/bash") {c ->

                            logs = sh (
                              script: "docker logs ${c.id}",
                              returnStatus: true
                            )

                            echo "LOGS RETURN CODE : ${logs}"
                            if (logs == 0) {
                                echo "LOGS SUCCESS"
                            } else {
                                echo "LOGS FAILURE"
                                sh "exit 1" // this fails the stage
                                //currentBuild.result = 'FAILURE'
                            }
                          } // docker.image

                          containers.put("ubuntu-18.04", container)

                        } // withCredentials

                      } // ANSIBLE_VAULT_PASSWORD
                    } // vault configFileProvider

                  } catch (exc) {
                    echo 'Error: There were errors in tests : ' + exc.toString()
                    currentBuild.result = 'UNSTABLE'
                    logs = "FAIL" // make sure other exceptions are recorded as failure too
                    //error 'There are errors in tests'
                  } finally {
                    echo "finally"
                  } // finally

                  cst = sh (
                    script: "bash scripts/docker-test.sh ${DOCKER_NAME} ${DOCKER_TAG_NEXT_UBUNTU_18} 2>&1 > docker-build-ubuntu-18.04-cst.log ",
                    returnStatus: true
                  )

                  echo "CONTAINER STRUCTURE TEST RETURN CODE : ${cst}"
                  if (cst == 0) {
                    echo "CONTAINER STRUCTURE TEST SUCCESS"
                  } else {
                    echo "CONTAINER STRUCTURE TEST FAILURE"
                    echo "WARNING : CST failed, check output at ${env.BUILD_URL}artifact/docker-build-ubuntu-18.04-cst.log"
                    // and ${env.BUILD_URL}artifact/docker-build-cst.json
                    currentBuild.result = 'UNSTABLE'
                  }

                  echo "Init result: ${currentBuild.result}"
                  echo "Init currentResult: ${currentBuild.currentResult}"

                } // tee
              } // if
            } // script
          } // steps
          post {
            always {
              archiveArtifacts artifacts: "docker-build-cst.json, *.log, target/ansible-lint*, docker/**/config*.yaml, docker/**/Dockerfile*", onlyIfSuccessful: false, allowEmptyArchive: true
            }
          } // post
        } // stage Ubuntu 18.04
        stage('Ubuntu 20.04') {
          when {
            expression { env.BRANCH_NAME ==~ /release\/.+|master|develop|PR-.*|feature\/.*|bugfix\/.*/ }
            expression { params.BUILD_ONLY == false && params.BUILD_DOCKER == true && params.BUILD_DOCKER_UBUNTU20 == true }
          }
          steps {
            script {
              if (! params.SKIP_DOCKER) {

                tee('docker-build-ubuntu-20.04.log') {

                    try {

                      configFileProvider([configFile(fileId: 'vault.passwd',  targetLocation: 'vault.passwd', variable: 'ANSIBLE_VAULT_PASSWORD_FILE')]) {

                        withCredentials([string(credentialsId: 'fr-ansible-vault-password', variable: 'ANSIBLE_VAULT_PASSWORD')]) {

                          sh 'mkdir -p .ssh/ || true'

                          DOCKER_TAG_NEXT_UBUNTU_20="1.1.0"

                          DOCKER_BUILD_ARGS=" --pull --build-arg ANSIBLE_VAULT_PASSWORD=${ANSIBLE_VAULT_PASSWORD}"
                          DOCKER_BUILD_ARGS+= getDockerProxyOpts(isProxy: true)

                          if (isCleanRun() == true) {
                            DOCKER_BUILD_ARGS+=" --no-cache"
                          }

                         withCredentials([
                             [$class: 'UsernamePasswordMultiBinding',
                             credentialsId: DOCKER_REGISTRY_CREDENTIAL,
                             usernameVariable: 'USERNAME',
                             passwordVariable: 'PASSWORD']
                         ]) {
                           def container = docker.build("${DOCKER_ORGANISATION}/${DOCKER_NAME}:${DOCKER_TAG_NEXT_UBUNTU_20}", "${DOCKER_BUILD_ARGS} -f docker/ubuntu20/Dockerfile . ")
                           container.inside {
                             sh 'echo test'
                           }

                           //docker run -i -t --entrypoint /bin/bash ${myImg.imageName()}
                           docker.image("${DOCKER_ORGANISATION}/${DOCKER_NAME}:${DOCKER_TAG_NEXT_UBUNTU_20}").withRun("-u root --entrypoint='/entrypoint.sh'", "/bin/bash") {c ->
                             logs = sh (
                               script: "docker logs ${c.id}",
                               returnStatus: true
                             )

                             echo "LOGS RETURN CODE : ${logs}"
                             if (logs == 0) {
                                 echo "LOGS SUCCESS"
                             } else {
                                 echo "LOGS FAILURE"
                                 sh "exit 1" // this fails the stage
                                 //currentBuild.result = 'FAILURE'
                             }

                           } // docker.image

                           containers.put("ubuntu-20.04", container)

                        } // withCredentials

                        echo "TODO JUNIT"

                        // TODO
                        //junit "target/jenkins-full-*.xml"
                        //junit "ansible-lint.xml, pylint-junit-result.xml"

                        } // ANSIBLE_VAULT_PASSWORD

                      } // vault configFileProvider

                    } catch (exc) {
                      echo 'Error: There were errors in tests. '+exc.toString()
                      currentBuild.result = 'UNSTABLE'
                      logs = "FAIL" // make sure other exceptions are recorded as failure too
                      //error 'There are errors in tests'
                    } finally {
                      echo "finally"
                    } // finally

                    cst = sh (
                      script: "export CST_CONFIG=docker/ubuntu20/config.yaml && bash scripts/docker-test.sh ${DOCKER_NAME} ${DOCKER_TAG_NEXT_UBUNTU_20} 2>&1 > docker-build-ubuntu-20.04-cst.log ",
                      returnStatus: true
                    )

                    echo "CONTAINER STRUCTURE TEST RETURN CODE : ${cst}"
                    if (cst == 0) {
                      echo "CONTAINER STRUCTURE TEST SUCCESS"
                    } else {
                      echo "CONTAINER STRUCTURE TEST FAILURE"
                      echo "WARNING : CST failed, check output at ${env.BUILD_URL}artifact/docker-build-ubuntu-20.04-cst.log"
                      //currentBuild.result = 'UNSTABLE'
                    }

                    echo "Init result: ${currentBuild.result}"
                    echo "Init currentResult: ${currentBuild.currentResult}"

                    sh "docker images"

                    if (isReleaseBranch()) {
                      String DOCKER_IMAGE_BUILD="${DOCKER_ORGANISATION}/${DOCKER_NAME}:${DOCKER_TAG_NEXT_UBUNTU_20}".trim()
                      String DOCKER_IMAGE_NEXT="${DOCKER_REGISTRY_HUB}/${DOCKER_ORGANISATION}/${DOCKER_NAME}:${DOCKER_TAG_NEXT_UBUNTU_20}".trim()

                      try {
                        sh "docker tag ${DOCKER_IMAGE_BUILD} ${DOCKER_IMAGE_NEXT}"
                        //sh "docker push ${DOCKER_IMAGE_NEXT}"
                      } catch (exc) {
                        echo "Warn: There was a problem pushing image to registry " + exc.toString()
                        currentBuild.result = 'UNSTABLE'
                      }
                    } // isReleaseBranch

                } // tee

              }
            }
          } // steps
          post {
            always {
              archiveArtifacts artifacts: "docker-*.json, *.log, target/ansible-lint*, docker/**/config*.yaml, docker/**/Dockerfile*", onlyIfSuccessful: false, allowEmptyArchive: true
            }
          } // post
        } // stage Ubuntu 20.04
        stage('Sample project') {
          when {
            expression { BRANCH_NAME ==~ /(release|master|develop)/ }
          }
          steps {
            script {

              echo "Init result: ${currentBuild.result}"
              echo "Init currentResult: ${currentBuild.currentResult}"

              String DOCKER_IMAGE_BUILD="${DOCKER_ORGANISATION}/${DOCKER_NAME}:${DOCKER_TAG_NEXT}".trim()
              String DOCKER_IMAGE_NEXT="${DOCKER_REGISTRY_HUB}/${DOCKER_ORGANISATION}/${DOCKER_NAME}:${DOCKER_TAG_NEXT}".trim()

              if (JENKINS_URL ==~ /https:\/\/albandrieu.*\/jenkins\/|https:\/\/todo.*\/jenkins\// ) {
                echo "JENKINS is supported"
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                  build job:'nabla-servers-bower-sample/master', propagate: false, wait: true
                }
              } // JENKINS_URL

            }
          }
        } // stage Sample project
      }
    }
  }
  post {
    always {
      node('molecule') {

        withLogParser(failBuildOnError:false, unstableOnWarning: false)

      } // node
      archiveArtifacts artifacts: "*.log, .scannerwork/*.log, roles/*.log, target/ansible-lint*", onlyIfSuccessful: false, allowEmptyArchive: true
    }
    //cleanup {
    //  wrapCleanWsOnNode()
    //} // cleanup
  } // post
}
