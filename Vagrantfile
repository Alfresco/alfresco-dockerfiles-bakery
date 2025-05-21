Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.provision "shell", path: "./vagrant_provision.sh", privileged: true
  config.vm.network "private_network", ip: "192.168.56.100"
  config.vm.network "forwarded_port", guest: 8080, host: 8080
  config.ssh.extra_args = ["-t", "cd /vagrant; bash --login"]
  config.vm.provider "virtualbox" do |v|
    v.memory = 10240
    v.cpus = 4
  end
end
