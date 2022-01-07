# Ansible

Ansible is a automation tool used for configuring servers. The architecture is fairly simple: 

One server acts as a control node. You install the ansible RPM on it, which includes the `ansible` command and so called ansible modules. Ansible is simple because it only uses SSH to configure servers. You don't need to install an agent on the servers. (Some configuration tasks might require certain Python modules to be installed on the servers, however.) The control node only needs SSH access to the hosts. The control node SSH into the hosts and runs a series of regular commands to achieve the state you configured on the control node, much like a sysadmin would configure servers manually. The automation happens on the control node. 

On the control node you write so-called "playbooks", which is just a file in which you state in order what tasks should be performed on the hosts. One task could be "install httpd", followed by "allow connections on port 80". You also state which hosts the playbook should apply to. Below is a very basic example playbook.

```
---
- name: Install and start Apache HTTPD
  hosts: web
  tasks:
    - name: httpd package is present
      yum:
        name: httpd
        state: present

    - name: correct index.html is present
      copy:
        src: files/index.html
        dest: /var/www/html/index.html

    - name: httpd is started
      service:
        name: httpd
        state: started
        enabled: true
```

Playbooks are written in YAML format. The `hosts` directive specifies the group of hosts to run the playbooks on. There are three tasks in this playbook and each task employs an _ansible module_. Here, they are `yum`, `copy`, and `service`. These are written in Python and run on the control node in the order specified when the playbook is fed to the ansible command. The modules are responsible for SSH-ing into the hosts and do whatever the module is programmed to do. We only give parameteres to the modules, like `state`, `src`, and `enabled`. 

An important design principle of ansible is that a task is only performed if the target host does not already satify the configuration given by the task. If, for example, httpd is already installed, ansible will simply report back that no changes were made. _A playbook should therefore be viewed as a description of a particular configuration *state* that you wish your hosts to have._ This means that if one or more hosts in a host group were to deviate from the configuration, you can run the playbook again against all the hosts in the group, and changes will only be applied to those hosts whose configuration don't align with the state described by the playbook.

There is of course a lot more to ansible than the introduction above, but that is the general principle.

# Redfish API
