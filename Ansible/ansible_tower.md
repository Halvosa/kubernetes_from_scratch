# Ansible Tower

Ansible Tower is the enterprise version of Ansible, and it helps organizations and teams scale quickly and effectively. Tower adds the following features on top of Ansible:
 * A graphical user interface dashboard.
 * Role-based access control.
 * Job scheduling.
 * Graphical inventory management.
 * A multi-playbook workflow.
 * RESTful APIs.
 * External logging integrations.
 * Real-time job status updates.
 * Red Hat technical support.
 * Red Hat Customer Portal access.
(https://www.redhat.com/sysadmin/intro-ansible-tower)

The main take-away is that Tower adds a graphical web interface, RBAC, job scheduling and a REST API. RBAC is probably the most important difference between pure Ansible and Ansible Tower.

## Ansible Tower vs AWX

_"The AWX project—AWX for short—is an open source community project, sponsored by Red Hat, that enables users to better control their community Ansible project use in IT environments. AWX is the upstream project from which the automation controller component is ultimately derived." (https://www.ansible.com/products/awx-project/faq)_

(Ansible Automation Controller is a renaming of Ansible Tower.) 

We will install Ansible Tower, but the difference between it and AWX should be minimal. 

## Installation

Ansible Tower can be installed either on a VM or on OpenShift. To makes things simple, let's first deploy it on a VM.

Some key take-aways from the official installation guide (https://docs.ansible.com/ansible-tower/latest/html/quickinstall/index.html) and the general installation notes (https://docs.ansible.com/ansible-tower/3.8.5/html/installandreference/install_notes_reqs.html#ir-general-install-notes):

```
Prerequisites:
 * Must be installed on a separate VM because of so many dependencies.
 * If you need to access a HTTP proxy to install software from your OS vendor, ensure that the environment variable “HTTP_PROXY” is set accordingly before running setup.sh. 
 * The Tower installer creates a self-signed SSL certificate and keyfile at /etc/tower/tower.cert and /etc/tower/tower.key for HTTPS communication. 
    These can be replaced after install with your own custom SSL certificates if you desire, but the filenames are required to be the same.
 * Tower installation must be run from an internet connected machine...
  
Notes:
 * The latest version of Ansible is installed automatically during the setup process. 
```

# Deploying Ansible Tower on OpenShift


# Links
 * OpenShift Deployment and Configuration: https://docs.ansible.com/ansible-tower/3.8.5/html/administration/openshift_configuration.html#ag-openshift-configuration
 * Product overview: https://www.redhat.com/en/resources/ansible-automation-platform-datasheet
