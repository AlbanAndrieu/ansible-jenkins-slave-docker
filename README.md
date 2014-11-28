## NABLA Deployment

- Requires Ansible 1.6.3 or newer
- Expects Ubuntu or CentOS/RHEL 6.x hosts

These playbooks deploy a very basic jenkinsslave with all the required tool needed for a developper or buildmaster or devops to work on NABLA.
It will be used to create a Docker image.
Goal of this project is to integrate of several roles done by the community. 
Goal is to contribuate to the community as much as possible instead of creating a new role.
Goal is to ensure following roles (GIT submodules) to work in harmony.

Then run the playbook, like this:

	ansible-playbook -i hosts -c local -v jenkins-slave.yml -vvvv
	or
	setup.sh

When the playbook run completes, you should be able to build and test any NABLA project, on the target machines.

This is a very simple playbook and could serve as a starting point for more complex projects. 

### Ideas for improvement

Here are some ideas for ways that these playbooks could be extended:

- Feel free to ask.

We would love to see contributions and improvements, so please fork this
repository and send us your changes via pull requests.
