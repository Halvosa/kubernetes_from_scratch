# DRAFT - Provisioning Cluster Nodes with Ansible 

## Ansible

Ansible is a automation tool used for configuring servers. At the most basic level, the architecture is fairly simple: One server acts as a control node. You install the ansible RPM on it, which includes the `ansible` command and so-called ansible modules (and of course, the brain of ansible, the ansible automation controller). Ansible is simple because it only uses SSH to configure servers. You don't need to install an agent on the servers. (Some configuration tasks might require certain Python modules to be installed on the servers, however.) The control node only needs SSH access to the hosts. The control node SSH into the hosts and runs a series of regular commands to achieve the state you configured on the control node, much like a sysadmin would configure servers manually. The automation happens on the control node. 

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

Ansible also has a `uri` module that, instead of SSH-ing into the hosts, simply performes an HTTP request from the control node. This can be useful for many things, for example to retrieve a file from a web server that in the next task in the playbook should be distributed out to the hosts. Or it can be used to interface with a web API.

There is of course a lot more to ansible than the introduction above, but that is the general principle.

## BMC's and the Redfish API

A baseboard management controller (BMC) is a specialized service processor that monitors the physical state of a computer, server or other hardware devices. It can be used to administer a device through an independent connection. One example of a BMC is Integrated Lights-Out (iLO), which you'll find in servers from HP. iLO is basically a small computer inside the server's chassis with a separate power supply and a dedicated network interface. iLO runs a web server on its network interface that a system administrator can log onto and gain access to hardware related settings as well as a web console for the server. From the BMC, you can even shut down the server and bring it back up without losing access to the BMC.

Since graphical web interfaces are not very suitable for automation, BMC's commonly also provide an API. Redfish is an industry standard RESTful API specification for IT infrastructure. It uses HTTPS and the JSON format.

We can use sushy-tools to emulate a BMC with Redfish API. The package ships two simulators – static Redfish responder and virtual Redfish BMC that is backed by libvirt or OpenStack cloud. We're interested in the latter. From the official git repository (https://github.com/openstack/sushy-tools):

>"The virtual Redfish BMC resembles the real Redfish-controlled bare-metal machine to some extent. 
>Some client queries are translated to commands that actually control VM instances simulating bare metal hardware. 
>However some of the Redfish commands just return static content never touching the virtualization backend..."


Documentation can be found at https://docs.openstack.org/sushy-tools/latest/install/index.html. Let us now set up a virtual Redfish BMC to control our libvirt-based cluster node VM's, such that we can simulate the provisioning of physical cluster nodes with Ansible. 

```console
halvor@halvor-NUC:~$ sudo pip install sushy-tools
halvor@halvor-NUC:~$ sudo pip install libvirt-python
Requirement already satisfied: libvirt-python in /usr/lib/python3/dist-packages (6.1.0)
halvor@halvor-NUC:~$ which sushy-emulator 
/home/halvor/.local/bin/sushy-emulator
```
Creating a systemd unit file for simplicity:

```console
halvor@halvor-NUC:~$ sudo bash -c 'cat << EOF > /etc/systemd/system/sushy-emulator.service
> [Unit]
> Description=Sushy Libvirt emulator
> After=syslog.target
> 
> [Service]
> Type=simple
> ExecStart=/home/halvor/.local/bin/sushy-emulator --port 8000 --libvirt-uri "qemu:///system"
> StandardOutput=syslog
> StandardError=syslog
> EOF'
```

We can now start the Redfish API BMC service and curl then curl the server to see if it works:

```console
halvor@halvor-NUC:~$ sudo systemctl start sushy-emulator
halvor@halvor-NUC:~$ curl localhost:8000/redfish/v1/
{
    "@odata.type": "#ServiceRoot.v1_0_2.ServiceRoot",
    "Id": "RedvirtService",
    "Name": "Redvirt Service",
    "RedfishVersion": "1.0.2",
    "UUID": "85775665-c110-4b85-8989-e6162170b3ec",
    "Systems": {
        "@odata.id": "/redfish/v1/Systems"
    },
...output omitted...
```

Let's see if we can start the VM k8s-master via Redfish:

```console
halvor@halvor-NUC:~$ curl localhost:8000/redfish/v1/Systems
{
    "@odata.type": "#ComputerSystemCollection.ComputerSystemCollection",
    "Name": "Computer System Collection",
    "Members@odata.count": 8,
    "Members": [
        
            {
                "@odata.id": "/redfish/v1/Systems/d9833cb5-4e83-4ced-8df9-87e07f837ca0"
            },
        
            {
                "@odata.id": "/redfish/v1/Systems/9a71e255-1a67-430f-a178-809dfbce329a"
            },
        
            {
                "@odata.id": "/redfish/v1/Systems/07f98172-86f7-4b4b-bddb-0d642373debb"
            },
        
...output omitted...
            
halvor@halvor-NUC:~$ curl localhost:8000/redfish/v1/Systems/d9833cb5-4e83-4ced-8df9-87e07f837ca0
{
    "@odata.type": "#ComputerSystem.v1_1_0.ComputerSystem",
    "Id": "d9833cb5-4e83-4ced-8df9-87e07f837ca0",
    "Name": "Vagrant_k8s-master",
    "UUID": "d9833cb5-4e83-4ced-8df9-87e07f837ca0",
    "Manufacturer": "Sushy Emulator",
    "Status": {
        "State": "Enabled",
        "Health": "OK",
        "HealthRollUp": "OK"
    },
    "PowerState": "Off",
    "Boot": {
        "BootSourceOverrideEnabled": "Continuous",
        "BootSourceOverrideTarget": "Hdd",
        "BootSourceOverrideTarget@Redfish.AllowableValues": [
            "Pxe",
            "Cd",
            "Hdd"
        ]
    },
    "ProcessorSummary": {
        "Count": 2,
        "Status": {
            "State": "Enabled",
            "Health": "OK",
            "HealthRollUp": "OK"
        }
    },
    "MemorySummary": {
        "TotalSystemMemoryGiB": 1,
        "Status": {
            "State": "Enabled",
            "Health": "OK",
            "HealthRollUp": "OK"
        }
    },
    "Bios": {
        "@odata.id": "/redfish/v1/Systems/d9833cb5-4e83-4ced-8df9-87e07f837ca0/BIOS"
    },
    "Processors": {
        "@odata.id": "/redfish/v1/Systems/d9833cb5-4e83-4ced-8df9-87e07f837ca0/Processors"
    },
    "Memory": {
        "@odata.id": "/redfish/v1/Systems/d9833cb5-4e83-4ced-8df9-87e07f837ca0/Memory"
    },
    "EthernetInterfaces": {
        "@odata.id": "/redfish/v1/Systems/d9833cb5-4e83-4ced-8df9-87e07f837ca0/EthernetInterfaces"
    },
    "SimpleStorage": {
        "@odata.id": "/redfish/v1/Systems/d9833cb5-4e83-4ced-8df9-87e07f837ca0/SimpleStorage"
    },
    "Storage": {
        "@odata.id": "/redfish/v1/Systems/d9833cb5-4e83-4ced-8df9-87e07f837ca0/Storage"
    },
    
...output omitted...
    
    "Actions": {
        "#ComputerSystem.Reset": {
            "target": "/redfish/v1/Systems/d9833cb5-4e83-4ced-8df9-87e07f837ca0/Actions/ComputerSystem.Reset",
            "ResetType@Redfish.AllowableValues": [
                "On",
                "ForceOff",
                "GracefulShutdown",
                "GracefulRestart",
                "ForceRestart",
                "Nmi",
                "ForceOn"
            ]
        }
    },
    
...output omitted...

halvor@halvor-NUC:~$ virsh list
 Id   Name   State
--------------------

halvor@halvor-NUC:~$ curl -X POST localhost:8000/redfish/v1/Systems/d9833cb5-4e83-4ced-8df9-87e07f837ca0/Actions/ComputerSystem.Reset -H 'Content-Type: application/json' -d '{"ResetType":"On"}'
halvor@halvor-NUC:~$ virsh list
 Id   Name                 State
------------------------------------
 6    Vagrant_k8s-master   running
```

## Creating a Blank VM

```console
root@halvor-NUC:~# ip link add br_redfish type bridge
root@halvor-NUC:~# ip addr add 10.5.5.1/24 dev br_redfish
root@halvor-NUC:~# ip link set br_redfish up
```

```console
root@halvor-NUC:~# qemu-img create -f qcow2 /var/lib/libvirt/images/redfish_test.qcow2 16G
root@halvor-NUC:~# virt-install --connect="qemu:///system" -n redfish_test --os-type=Linux --os-variant=fedora31 --ram=1024 --vcpus=2 --disk /var/lib/libvirt/images/redfish_test.qcow2 --graphics none --network bridge:br_redfish --boot hd
```




## Setting up Ansible

```console
root@halvor-NUC:~# apt install -y ansible
root@halvor-NUC:~# useradd ansible
root@halvor-NUC:~# passwd ansible
```

