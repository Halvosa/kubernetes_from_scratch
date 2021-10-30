# Kubernetes From Scratch

*Goal: To become familiar with the inner workings of a Kubernetes cluster.*

We will set up a Kubernetes cluster component for component in a virtual environment. The setup will be as follows:
  * A physical Intel NUC host on which we will set up the virtual environment. 
    * Hostname: *halvor-NUC*
    * OS: Ubuntu 20.04
  * One VM responsible for the control plane. 
    * Hostname: *k8s-master* 
    * OS: CentOS 8 Stream.
  * Two worker node VMs: 
    * Hostnames: *node-1* and *node-2* 
    * OS: CentOS 8 Stream.

Before we begin, I will assume that the physical host (halvor-NUC) has already been set up with a clean install of Ubuntu and that you have root access.

## Setting up the VMs
We will use libvirt and vagrant, but one could just as well use for example virtualbox. 

```console
halvor@halvor-NUC:~$ cat /etc/lsb-release 
DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=20.04
DISTRIB_CODENAME=focal
DISTRIB_DESCRIPTION="Ubuntu 20.04.2 LTS"
halvor@halvor-NUC:~$ sudo apt install virt-manager
halvor@halvor-NUC:~$ sudo apt install vagrant
halvor@halvor-NUC:~$ mkdir -p /home/halvor/lab/Vagrant
halvor@halvor-NUC:~$ cd /home/halvor/lab/Vagrant
halvor@halvor-NUC:~/lab/Vagrant$ vim Vagrantfile
```
The file Vagrantfile is where we tell Vagrant what to provision for us. Inside it we put the following:
```ruby
IMAGE_NAME = "centos/stream8"
N = 2

Vagrant.configure("2") do |config|

    config.vm.provider "libvirt" do |v|
            v.memory = 1024
            v.cpus = 2
    end
      
    config.vm.define "k8s-master" do |master|
       master.vm.box = IMAGE_NAME
        master.vm.network "private_network", ip: "192.168.50.10"
        master.vm.hostname = "k8s-master"
        end

    (1..N).each do |i|
        config.vm.define "node-#{i}" do |node|
                node.vm.box = IMAGE_NAME
                    node.vm.network "private_network", ip: "192.168.50.#{i + 10}"
            node.vm.hostname = "node-#{i}"
            end
        end
end
```

Next, we spin up the VMs by running "vagrant up". Vagrant will then provision the VMs according to the Vagrantfile using libvirt.

```console
halvor@halvor-NUC:~/lab/Vagrant$ vagrant up
Bringing machine 'k8s-master' up with 'libvirt' provider...
Bringing machine 'node-1' up with 'libvirt' provider...
Bringing machine 'node-2' up with 'libvirt' provider...
==> node-1: Box 'centos/stream8' could not be found. Attempting to find and install...
...output omitted...
```

A _.vagrant_ directory has now been created under _/home/halvor/lab/Vagrant_. While the VMs are running, we can SSH into them like so:

```console
halvor@halvor-NUC:~/lab/Vagrant$ vagrant ssh node-1
Last login: Fri Oct 29 18:41:48 2021 from 192.168.121.1
[vagrant@node-1 ~]$ cat /etc/redhat-release 
CentOS Stream release 8
```

## CRI-O Runtime
_https://cri-o.io/_

Worker nodes run containers under orders from the control plane. Every worker node must therefore have a program installed that can start, stop and do basic operations on containers, i.e. a container runtime/engine. We will use CRI-O with runc for this. 

CRI-O major and minor version must match the Kubernetes version that we will install later, so keep that in mind. Thus, before installing CRI-O, make sure that the corresponding Kubernetes version is available to you. To install CRI-O, run the following as root:

```console
[root@node-1 ~]# OS=CentOS_8_Stream
[root@node-1 ~]# VERSION=1.21
[root@node-1 ~]# curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/devel:kubic:libcontainers:stable.repo
curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo
[root@node-1 ~]# yum install cri-o
[root@node-1 ~]# systemctl enable --now crio
```

## Kubelet
The Kubernetes control plane will not interact with the runtime directly. Instead it communicates with an agent that must be installed on every worker node in addition to the runtime. The agent is called "kubelet". It accepts PodSpecs/container manifests (a YAML or JSON object that describes a pod) in various ways and ensures that pods run on the worker node according to the PodSpecs. Manifests are handed to kubelet primarily from the control plane api server, but can technically also be done manually.

_"In standard docker kubernetes cluster, kubelet is running on each node as systemd service and is taking care of communication between runtime and api service. It is reponsible for starting microservices pods (such as kube-proxy, kubedns, etc. - they can be different for various ways of deploying k8s) and user pods. Configuration of kubelet determines which runtime is used and in what way."_ (https://github.com/cri-o/cri-o/blob/main/tutorials/kubernetes.md),

### Turning off swap
Kubelet does not currently support using swap. The explanation is that “Kubernetes did not support the use of swap memory on Linux, as it is difficult to provide guarantees and account for pod memory utilization when swap is involved. As part of Kubernetes' earlier design, swap support was considered out of scope, and a kubelet would by default fail to start if swap was detected on a node.” (https://kubernetes.io/blog/2021/08/09/run-nodes-with-swap-alpha/)

```console
[root@node-1 ~]# swapon --show
NAME      TYPE SIZE USED PRIO
/swapfile file   2G   3M   -2
[root@node-1 ~]# swapoff -a
```

The swapfile should also be removed from _/etc/fstab_ to ensure that swap is not mounted again on boot! 

### Downloading and Installing the Binary
Since we chose version 1.21 for CRI-O, we must make sure that the Kubernetes binaries have the same version. The binaries can be found here: https://www.downloadkubernetes.com/. Right now, we only need the kubelet binary.

```console
[root@node-1 ~]# crio -v
crio version 1.21.3
...output omitted...
[root@node-1 ~]# yum install -y wget
[root@node-1 ~]# wget https://dl.k8s.io/v1.21.6/bin/linux/amd64/kubelet
[root@node-1 ~]# mv kubelet /usr/bin
[root@node-1 ~]# chmod o+x /usr/bin/kubelet
```

### Running Kubelet
Manifests can be handed to Kubelet in several different ways, see https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/. One way is to provide Kubelet with a path to a directory that it will then check for updates every 20 seconds. The default location for static manifests is _/etc/kubernetes/manifests_ (https://kubernetes.io/docs/reference/setup-tools/kubeadm/implementation-details/).

We wish to provide some lengthy parameteres to Kubelet when launching it, so let us put it in a script so we do not have to type it every time.

```console
[root@node-1 ~]# mkdir -p /etc/kubernetes/manifests    (is this dir used by the api server?)
[root@node-1 ~]# mkdir -p /var/log/containers
[root@node-1 ~]# vi start_kubelet.sh        (could make a service for this)
[root@node-1 ~]# cat start_kubelet.sh 
#!/bin/bash
kubelet --pod-manifest-path=/etc/kubernetes/manifests \
 --container-runtime=remote \
 --container-runtime-endpoint=unix:///var/run/crio/crio.sock \
 &> /var/log/containers/kubelet.log
[root@node-1 ~]# chmod o+x start_kubelet.sh
[root@node-1 ~]# ./start_kubelet &
[1] 2915
```

As mentioned above, Kubelet will check the given path every 20 seconds for YAML manifests and provision pods based on that. We log stdin and stderr to kubelet.log, and we run the process as a job in the background. Kubelet and CRI-O communicate using gRPC, which uses HTTP under the hood. We had to specify the path to a Unix domain socket set up by CRI-O (https://en.wikipedia.org/wiki/Unix_domain_socket). 

If you take a look in kubelet.log, you will probably find this error:

```console
E1029 22:04:01.076306    2916 remote_runtime.go:116] "RunPodSandbox from runtime service failed" err="rpc error: code = Unknown desc = cri-o configured with systemd cgroup manager, but did not receive slice as parent: /kubepods/besteffort/pod19da9fa0d08737487dc32786dfe9d250"
```

To fix this, we first need to stop Kubelet:
```console
[root@node-1 ~]# jobs
[1]+  Running       
[root@node-1 ~]# fg 1
./start_kubelet.sh
^C[root@node-1 ~]#
```

Next, we simply add the parameter "--cgroup-driver=systemd" to _start_kubelet.sh_ and launch Kubelet again.


## Etcd
https://alibaba-cloud.medium.com/getting-started-with-kubernetes-etcd-a26cba0b4258 
## Links
Kubernetes binaries:
https://www.downloadkubernetes.com/ 

Kubelet doc:
https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/ 

What is CRI-O?
https://cri-o.io/
https://docs.openshift.com/container-platform/3.11/crio/crio_runtime.html 
https://learn.redhat.com/t5/Containers-DevOps-OpenShift/podman-vs-CRI-O-vs-RunC/td-p/9639 
https://access.redhat.com/documentation/en-us/openshift_container_platform/3.11/html/cri-o_runtime/use-crio-engine 
https://merlijn.sebrechts.be/blog/2020-01-docker-podman-kata-cri-o/ 

Configuring kubelet to use CRIO instead of Docker:
https://github.com/cri-o/cri-o/blob/main/tutorials/kubernetes.md 

Error: “cri-o configured with systemd cgroup manager, but did not receive slice as parent”:
https://github.com/cri-o/cri-o/issues/1284 

gRPC vs REST:
https://cloud.google.com/blog/products/api-management/understanding-grpc-openapi-and-rest-and-when-to-use-them

Static 
