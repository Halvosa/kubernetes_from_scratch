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
      
      
Just like two physical hosts have their own NICs and network stack that can communicate via a physical switch, we can create virtual NICs in two or more network namespaces that we can hook up to a virtual switch/bridge to enable communication between the namespaces/individual network stacks.

[vagrant@test-1 ~]$ ip link add br-ns type bridge
