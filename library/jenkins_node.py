#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Custom Ansible Module to configure Jenkins Node using REST API
#
# # See https://support.cloudbees.com/hc/en-us/articles/115003896171-Creating-node-with-the-REST-API for documentation
import json
import platform

import requests
from ansible.module_utils.basic import AnsibleModule


def get_system_ca_bundle():
    dist_name = platform.linux_distribution()[0].lower()
    if any(supported in dist_name for supported in ('centos', 'red hat', 'fedora')):
        return '/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem'
    if 'ubuntu' in dist_name:
        return '/etc/ssl/certs/ca-certificates.crt'
    return None


def prepare_mod_params(params):
    params = dict(params)
    if params['name'] in ('', None):
        params['name'] = params['hostname']
    params['sshHostKeyVerificationStrategy'] = '{}.{}'.format(
        'hudson.plugins.sshslaves.verifiers',
        params['sshHostKeyVerificationStrategy'],
    )
    return params


def delete_jenkins_node(params, verify=None):
    url_delete = 'https://{}/computer/{}/doDelete'.format(
        params['x_jenkins_server'],
        params['name'],
    )
    auth = (
        params['x_auth']['username'],
        params['x_auth']['password'],
    )
    headers = {
        'Jenkins-Crumb': params['x_token'],
        'Content-Type':  'application/x-www-form-urlencoded',
    }
    response = requests.post(
        url_delete,
        auth=auth,
        headers=headers,
        verify=verify,
    )
    return response


def configure_jenkins_node(params, verify=None):
    url_create_new = 'https://{}/computer/doCreateItem'.format(
        params['x_jenkins_server'],
    )
    url_update = 'https://{}/computer/{}/configSubmit'.format(
        params['x_jenkins_server'],
        params['name'],
    )
    https_params = {
        'name': params['name'],
        'type': params['type'],
    }
    auth = (
        params['x_auth']['username'],
        params['x_auth']['password'],
    )
    headers = {
        'Jenkins-Crumb': params['x_token'],
        'Content-Type':  'application/x-www-form-urlencoded',
    }
    labelString = ' '.join(params['labels'])
    configuration = {
        '':                  [
            params['agentLauncher'],
            params['retentionStrategy'],
        ],
        'labelString':       labelString,
        'launcher':          {
            '':                               '3',
            '$class':                         params['agentLauncher'],
            'credentialsId':                  params['credentialsId'],
            'host':                           params['hostname'],
            'javaPath':                       '',
            'jvmOptions':                     '',
            'launchTimeoutSeconds':           '',
            'maxNumRetries':                  '',
            'port':                           params['port'],
            'prefixStartSlaveCmd':            '',
            'retryWaitTime':                  '',
            'sshHostKeyVerificationStrategy': {
                '$class':        params['sshHostKeyVerificationStrategy'],
                'stapler-class': params['sshHostKeyVerificationStrategy'],
            },
            'stapler-class':                  params['agentLauncher'],
            'suffixStartSlaveCmd':            '',
        },
        'mode':              'NORMAL',
        'name':              params['name'],
        'nodeDescription':   params['nodeDescription'],
        'nodeProperties':    {
            'stapler-class-bag': 'true',
        },
        'numExecutors':      params['numExecutors'],
        'remoteFS':          params['remoteFS'],
        'retentionStrategy': {
            '$class':        params['retentionStrategy'],
            'stapler-class': params['retentionStrategy'],
        },
        'type':              params['type'],
    }
    # this configuration part is created separately, because we do not want to add
    # environment in node configuration, if there are no env vars or no tools at all
    if params['env'] != []:
        configuration['nodeProperties']['hudson-slaves-EnvironmentVariablesNodeProperty'] = {
            'env': params['env'],
        }
    if params['tools'] != []:
        configuration['nodeProperties']['hudson-tools-ToolLocationNodeProperty'] = {
            'locations': params['tools'],
        }
    data = 'json={}'.format(json.dumps(configuration))
    exists = requests.get(
        url_update,
        auth=auth,
        headers=headers,
        verify=verify,
    )
    if exists.status_code == 404:
        url = url_create_new
    else:
        url, params = url_update, None
    response = requests.post(
        url,
        data=data,
        params=https_params,
        auth=auth,
        headers=headers,
        verify=verify,
    )
    return response


def main():
    """
    Configures Jenkins node, using API.

    :param str name: **default** *""*, -
        visible machine name on Jenkins. If not provided, defaults to hostname

    :param str hostname: **Required** -
        name of the host to be added, can be FQDN, short name or IP address

    :param str state: **default** *"present"*, **choices** *["present", "absent"]* -
        whether node should or shouldn"t be present on Jenkins.
        *"present"* can be used both to create new node or reconfigure existing one.
        *"absent"* can be used to remove nodes from Jenkins.

    :param str credentialsIs: **default** *"1234"* -
        Credentials used, default corresponds to jenkins@unix-slaves on `jenkins`

    :param str nodeDescription: **default** *"Jenkins node automatically created by Ansible"*

    :param list labels: **default** *[]*

    :param list env: **default** *[]* -
        a list of dicts list of dicts in {key, value} format, for example:
        ``{ key: ARCH, value: x86Linux }``

    :param list tools: **default** *[]* -
        a list of dicts in {key, home} format, for example:
        ``{ key: "hudson.plugins.git.GitTool$DescriptorImpl@git-system", home: "usr/bin/git" }``

    :param str remoteFS: **default** */home/jenkins*

    :param int numExecutors: **default** *1*

    :param str type: **default** *"hudson.slaves.DumbSlave"*

    :param str sshHostKeyVerificationStrategy: **default** *"NonVerifyingKeyVerificationStrategy"*
        **choices** *["NonVerifyingKeyVerificationStrategy", "KnownHostsFileKeyVerificationStrategy"]*

    :param int port: **default** *22*

    :param str x_jenkins_server: **default** *"localhost/jenkins"*

    :param dict x_auth: **Required** -
        credentials for Jenkins server, in the for of ``username``, ``password``.

    :param str x_token: **Required** -
        CSRF token, retrieved by ``jenkins_csrf_token`` module

    :example:

    .. code-block:: yaml

        jenkins_node:
          hostname: "testserver"
          state: present
          nodeDescription: |
            Node automatically configured by Ansible.
            Do not change configuration manually, use jenkins_node.yml playbook instead.
          labels:
           - centos7
           - x86Linux
          numExecutors: 1
          env:
          - key: ARCH
            value: x86Linux
          - key: JAVA_HOME
            value: /usr/java/default
          - key: NUMBER_OF_PROCESSORS
            value: "4"
          - key: PATH
            value: "$JAVA_HOME/bin:$PATH"
          tools:
          - key: "hudson.model.JDK$DescriptorImpl@java-latest"
            home: "/usr/java/latest"
          credentialsId: 1234 # jenkins@unix-slaves
          remoteFS: /workspace/slave
          x_jenkins_server: "localhos:8383/jenkins"
          x_token: "{{ csrf.token }}"
          x_auth:
            username: "{{ username }}"
            password: "{{ password }}"

    :returns: Msg

    """
    module = AnsibleModule(
        argument_spec={
            'name':         {
                'type':     'str',
                'default':  '',
                'required': False,

            },
            'hostname':         {
                'type':     'str',
                'required': True,

            },
            'state':            {
                'default': 'present',
                'choices': [
                    'present',
                    'absent',
                ],
            },
            'credentialsId':    {
                'type': 'str',
                'default': '1234',  # jenkins@unix-slaves

            },
            'agentLauncher':    {
                'type': 'str',
                'default': 'hudson.plugins.sshslaves.SSHLauncher',  # hudson.slaves.JNLPLauncher
            },

            'nodeDescription':  {
                'type': 'str',
                'default': 'Jenkins node automatically created by Ansible',

            },
            'labels':           {
                'type': 'list',
                'default': list(),

            },
            'env':              {
                'type': 'list',
                'default': list(),

            },
            'tools':            {
                'type': 'list',
                'default': list(),

            },
            'remoteFS':         {
                'type': 'str',
                'default': '/home/jenkins',

            },
            'numExecutors':     {
                'type': 'int',
                'default': 1,

            },
            'type':             {
                'type': 'str',
                'default': 'hudson.slaves.DumbSlave',

            },
            'retentionStrategy':             {
                'type': 'str',
                'default': 'hudson.slaves.RetentionStrategy$Always',
            },
            'sshHostKeyVerificationStrategy': {
                'type': 'str',
                'default': 'NonVerifyingKeyVerificationStrategy',
            },
            'port':             {
                'type': 'int',
                'default': 22,

            },
            'x_jenkins_server': {
                'type': 'str',
                'default': 'localhost/jenkins',

            },
            'x_auth':           {
                'type':     'dict',
                'required': True,  # username, password
            },
            'x_token':          {
                'type':     'str',
                'required': True,

            },
        },
    )
    ca_bundle = get_system_ca_bundle()
    params = prepare_mod_params(module.params)
    if ca_bundle is None:
        module.fail_json(
            msg='Unsupported Linux distribution, use CentOS7 or Ubuntu16',
        )
    if params['state'] == 'absent':
        delete_request = delete_jenkins_node(
            params,
            verify=ca_bundle,
        )
        if delete_request.status_code == 200:
            module.exit_json(
                changed=True,
                msg='Removed Jenkins node {}'.format(
                    params['name'],
                ),
            )
        if delete_request.status_code == 404:
            module.exit_json(
                changed=False,
                msg='Jenkins node does not exist {}'.format(
                    params['name'],
                ),
            )
        module.fail_json(
            changed=False,
            msg='Unchecked exception during node deletion: {} {}'.format(
                delete_request.status_code,
                delete_request.text,
            ),
        )
    if params['state'] == 'present':
        configure_request = configure_jenkins_node(
            params,
            verify=ca_bundle,
        )
        if configure_request.status_code == 403:
            module.fail_json(
                changed=False,
                msg='Authentication failed, either token is invalid or user does not have permissions to create new node. Error message: {}'.format(
                    configure_request.text,
                ),
            )
        if configure_request.status_code != 200:
            module.fail_json(
                changed=False,
                msg='Unchecked exception during node configuration: {} {}'.format(
                    configure_request.status_code,
                    configure_request.text,
                ),
            )
        module.exit_json(
            changed=True,
            msg='Configured Jenkins node {}'.format(params['name']),
        )


if __name__ == '__main__':
    main()
