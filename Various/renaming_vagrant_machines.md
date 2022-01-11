# How to Rename a Vagrant VM

If we have provisioned a VM using the Vagrantfile below, then we will have a VM on libvirt called "old-name.old-domain.local". We wish to rename this to "new-name.new-domain.local" without provisioning a new VM.

```ruby
Vagrant.configure("2") do |config|

	config.vm.provider "libvirt" do |v|
    		v.memory = 1024
    		v.cpus = 2
	end
      
	config.vm.define "old-name.old-domain.local" do |node|
    node.vm.box = IMAGE_NAME
		node.vm.hostname = "old-name.old-domain.local"
  end

end
```

To rename/change hostname of a virtual machine controlled by Vagrant, do the following:
  * Change FQDN in Vagrantfile
```ruby
Vagrant.configure("2") do |config|

	config.vm.provider "libvirt" do |v|
    		v.memory = 1024
    		v.cpus = 2
	end
      
	config.vm.define "new-name.new-domain.local" do |node|
    node.vm.box = IMAGE_NAME
		node.vm.hostname = "new-name.new-domain.local"
  end

end
```  
  * Change the name of the VMs in libvirt:

```console
# virsh shutdown old-name.old-domain.local
# virsh domrename old-name.old-domain.local new-name.new-domain.local
```

  * Change the name of the folders under .vagrant/machines/

```console
halvor@halvor-NUC:~/lab/Vagrant/.vagrant/machines$ mv old-name.old-domain.local new-name.new-domain.local
```

We can now run `vagrant up`:

```console
halvor@halvor-NUC:~/lab/Vagrant$ vagrant up
```





