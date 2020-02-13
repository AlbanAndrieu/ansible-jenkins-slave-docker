#!/usr/bin/env python
# -*- coding: utf-8 -*-
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


def get_csrf_token(host, auth, ca_bundle):
    url = 'https://{}/crumbIssuer/api/json'.format(host)
    response = requests.get(url, auth=(auth['username'], auth['password']), verify=ca_bundle)
    return response


def main():
    """
    Requests CSRF (cross-site request forgery) token from Jenkins, using API.
    Result of this module needs to be recorded, so that token can be in follow-up plays.
    Typically, result can be recorded as ``result`` and retrieved back as ``result.token``,

    :param str hostname: **default** *"albandrieu.com:8686/jenkins"* -
       full address of Jenkins server.
       If Jenkins server is not running on default route ('/'), relative route needs to be provided as well.

    :param dict auth: credentials for Jenkins server, in the for of ``username``, ``password``.

    :example:

    .. code-block:: yaml

        jenkins_csrf_token:
          hostname: "albandrieu.com:8383/jenkins"
          auth:
            username: "jenkins"
            password: "password"

    :returns: CSRF token

    """
    module = AnsibleModule(
        argument_spec={
            'hostname': {
                'type': 'str',
                'default': 'albandrieu.com:8383/jenkins',

            },
            'auth': {
                'type': 'dict',
                'required': True,  # username, password
            },
        },
    )
    ca_bundle = get_system_ca_bundle()
    if ca_bundle is None:
        module.fail_json(msg='Unsupported Linux distribution, use CentOS7 or Ubuntu16')
    token_request = get_csrf_token(
        module.params['hostname'],
        module.params['auth'],
        ca_bundle,
    )
    if token_request.status_code != 200:
        module.fail_json(
            msg='Request for CSRF token to Jenkins failed with status code {}'.format(token_request.status_code),
        )
    token = token_request.json()['crumb']
    module.exit_json(changed=True, token=token)


if __name__ == '__main__':
    main()
