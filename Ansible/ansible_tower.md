# Ansible Tower

## Installation

From the official installation guide (https://docs.ansible.com/ansible-tower/latest/html/quickinstall/index.html):

```
Prerequisites:
  * Must/should be installed on a separate VM because of so many dependencies.
  * If you need to access a HTTP proxy to install software from your OS vendor, ensure that the environment variable “HTTP_PROXY” is set accordingly before running     setup.sh 
  * The Tower installer creates a self-signed SSL certificate and keyfile at /etc/tower/tower.cert and /etc/tower/tower.key for HTTPS communication. 
    These can be   replaced after install with your own custom SSL certificates if you desire, but the filenames are required to be the same.
  * Starting with Ansible Tower 3.8, you must have valid subscriptions attached before installing and running the Ansible Automation Platform. A valid subscription     needs to be attached to the Automation Hub node only. Other nodes do not need to have a valid subscription/pool attached.
  * Note that the Tower installation must be run from an internet connected machine...
```

# Links
 * https://docs.ansible.com/ansible-tower/3.8.5/html/administration/openshift_configuration.html#ag-openshift-configuration
