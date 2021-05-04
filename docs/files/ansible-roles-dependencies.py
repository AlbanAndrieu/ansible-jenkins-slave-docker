#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import logging
from glob import glob

import graphviz
import yaml

logging.basicConfig(level=logging.DEBUG)

dot = graphviz.Digraph(name='roles')

role_nodes = {}


def add_role(role):
    logging.info('Adding role: %s', role)
    role_id = role.replace('/', '_')
    if role not in role_nodes:
        dot.node(role_id, role)
        role_nodes[role] = role_id


def link_roles(dependent, depended):
    logging.info('Adding dependency: %s -> %s', dependent, depended)
    dot.edge(
        role_nodes[dependent_role],
        role_nodes[depended_role],
    )


for path in glob('roles/*/meta/main.yml'):
    dependent_role = path.split('/')[1]

    add_role(dependent_role)

    with open(path, 'r') as f:
        for dependency in yaml.safe_load(f.read()).get('dependencies', []):
            try:
                if isinstance(dependency, str):
                    depended_role = dependency
                else:
                    depended_role = dependency.get('role')
                if depended_role:
                    add_role(depended_role)
                    link_roles(dependent_role, depended_role)
            except:
                logging.exception('Probleme with %s dependency: %s', dependent_role, dependency)
dot.format = 'png'
dot.render('roles.gv', view=True)
