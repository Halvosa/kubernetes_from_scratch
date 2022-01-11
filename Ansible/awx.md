# AWX

_"The AWX project—AWX for short—is an open source community project, sponsored by Red Hat, that enables users to better control their community Ansible project use in IT environments. AWX is the upstream project from which the automation controller component is ultimately derived." (https://www.ansible.com/products/awx-project/faq)_

AWX adds the following features on top of Ansible:
 * A graphical user interface dashboard.
 * Role-based access control.
 * Job scheduling.
 * Graphical inventory management.
 * RESTful APIs.
 * External logging integrations.
 * Real-time job status updates.

The main take-away is that AWX adds a graphical web interface, RBAC, job scheduling and a REST API. I believe RBAC is probably the most important difference between pure Ansible and AWX.

## Installation

The installation process for AWX is considerably more complicated than for Ansible Tower (now renamed to Ansible Automation Controller), partly because the installer takes care of everything for you. Also, the standard installation scenario for Tower is to deploy it on a single machine, although Red Hat does support OpenShift deployment (https://docs.ansible.com/ansible-tower/latest/html/quickinstall/prepare.html). For AWX, on the other hand, the preffered installation method is with the AWX Operator.




https://github.com/ansible/awx-operator
