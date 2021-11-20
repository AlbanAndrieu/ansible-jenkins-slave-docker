Roles & Playbooks
=================

TODO - it should be the most exhaustive section.

These playbooks deploy a very basic workstation with all the required tool needed for a developer or buildmaster to work on NABLA.

Then run the playbook, like this::

	ansible-playbook -i hosts -c local -v workstation.yml -vvvv

When the playbook run completes, you should be able to work on any NABLA project, on the target machines.

This is a very simple playbook and could serve as a starting point for more
complex projects.
Graphviz
---------

Generate graph:


.. code-block:: python3

	python ./docs/files/ansible-roles-dependencies.py

Files is:


.. literalinclude:: files/ansible-roles-dependencies.py
    :linenos:
    :language: python
    :emphasize-lines: 3, 10, 16, 22, 28 ,45-46

.. code-block:: bash

	dot -Tpng test.dot -o test.png

Output:

.. image:: files/test.png
   :width: 400pt


Folder Structure Conventions
----------------------------

> Folder structure options and naming conventions for software projects

A typical top-level directory layout:

.. code-block:: none

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

Use cases
---------

Minimal Jenkins Slave
~~~~~~~~~~~~~~~~~~~~~
