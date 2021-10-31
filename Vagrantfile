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
