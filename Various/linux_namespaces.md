man ip-netns: 
A network namespace is logically another copy of the network stack, with its own routes, firewall rules, and network devices.

       By default a process inherits its network namespace from its parent. Initially all the processes share the same default network namespace from the init process.

       By convention a named network namespace is an object at /var/run/netns/NAME that can be opened. The file descriptor resulting from opening /var/run/netns/NAME refers to
       the specified network namespace. Holding that file descriptor open keeps the network namespace alive.
       
(ip netns add NAME creates a persistent namespace (stays alive without parent process) because the namespace gets bind-mounted to a file in /var/run/netns/)

```console
[vagrant@test-1 ~]$ yum install -y httpd
[vagrant@test-1 ~]$ sudo ip netns add container
[vagrant@test-1 ~]$ ip netns list
container
[vagrant@test-1 ~]$ sudo ps -eo pid,ppid,user,netns,comm
    PID    PPID USER          NETNS COMMAND
      1       0 root     4026531992 systemd
      2       0 root     4026531992 kthreadd
...output omitted...
   4099     823 root     4026531992 sshd
   4103       1 vagrant  4026531992 systemd
   4107    4103 vagrant  4026531992 (sd-pam)
   4113    4099 vagrant  4026531992 sshd
   4114    4113 vagrant  4026531992 bash
...output omitted...
  23625    4114 root     4026531992 sudo
  23627   23625 root     4026531992 ps
```

All processes are in the same default namespace, inherited from systemd. 

We can execute a program in a given namespace with nsenter.

```console
[root@test-1 vagrant]# ps -eo pid,ppid,user,netns,args
    PID    PPID USER          NETNS COMMAND
      1       0 root     4026531992 /usr/lib/systemd/systemd --switched-root --system --deserialize 17
      2       0 root     4026531992 [kthreadd]
...output omitted...
   4099     823 root     4026531992 sshd: vagrant [priv]
   4103       1 vagrant  4026531992 /usr/lib/systemd/systemd --user
   4107    4103 vagrant  4026531992 (sd-pam)
   4113    4099 vagrant  4026531992 sshd: vagrant@pts/0
   4114    4113 vagrant  4026531992 -bash
...output omitted...
  23789    4114 root     4026531992 sudo nsenter --net=/var/run/netns/container /bin/bash
  23791   23789 root     4026532218 /bin/bash
  23810       2 root     4026531992 [kworker/0:2-events]
  23815   23791 root     4026532218 ps -eo pid,ppid,user,netns,args
[root@test-1 vagrant]# echo $$
23791
[root@test-1 vagrant]# ip link
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
```

As seen from the `ip link` command, the bash process we executed with nsenter now sees a totally separate network stack from the default that all other processes sees. 

man network_namespaces(7):
A virtual network (veth(4)) device pair provides a pipe-like
       abstraction that can be used to create tunnels between network
       namespaces, and can be used to create a bridge to a physical
       network device in another namespace.  When a namespace is freed,
       the veth(4) devices that it contains are destroyed.
      
      


https://developers.redhat.com/blog/2018/10/22/introduction-to-linux-interfaces-for-virtual-networking#vlan 

```console
[vagrant@test-1 ~]$ sudo ip link add veth0 type veth peer name veth1
[vagrant@test-1 ~]$ ip link
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
    link/ether 52:54:00:b2:8e:47 brd ff:ff:ff:ff:ff:ff
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
    link/ether 52:54:00:9a:ad:f8 brd ff:ff:ff:ff:ff:ff
4: veth1@veth0: <BROADCAST,MULTICAST,M-DOWN> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether fa:dd:05:6f:a0:48 brd ff:ff:ff:ff:ff:ff
5: veth0@veth1: <BROADCAST,MULTICAST,M-DOWN> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether 02:6c:1d:ad:f4:14 brd ff:ff:ff:ff:ff:ff
[vagrant@test-1 ~]$ sudo ip link set veth1 netns container
[vagrant@test-1 ~]$ ip link
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
    link/ether 52:54:00:b2:8e:47 brd ff:ff:ff:ff:ff:ff
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
    link/ether 52:54:00:9a:ad:f8 brd ff:ff:ff:ff:ff:ff
5: veth0@if5: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether 02:6c:1d:ad:f4:14 brd ff:ff:ff:ff:ff:ff link-netns container
```

Inside the container namespace we now have

```console
[root@test-1 vagrant]# ip link
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
5: veth1@if6: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether fa:dd:05:6f:a0:48 brd ff:ff:ff:ff:ff:ff link-netnsid 0
```

Now, let's add IP addresses and bring the interfaces to the up state:

```console
[vagrant@test-1 ~]$ sudo ip addr add 10.0.0.2/24 dev veth0
[vagrant@test-1 ~]$ sudo ip link set veth0 up
...and inside the container namespace...
[root@test-1 vagrant]# ip addr add 10.0.0.3/24 dev veth1
```

A route is automatically added to the routing table by the kernel (i.e. proto kernel):
```console
[root@test-1 vagrant]# ip r
10.0.0.0/24 dev veth1 proto kernel scope link src 10.0.0.3
```



Just like two physical hosts have their own NICs and network stack that can communicate via a physical switch, we can create virtual NICs in two or more network namespaces that we can hook up to a virtual switch/bridge to enable communication between the namespaces/individual network stacks.
[vagrant@test-1 ~]$ sudo ip link add br-ns type bridge
[vagrant@test-1 ~]$ sudo ip link set br-ns up

