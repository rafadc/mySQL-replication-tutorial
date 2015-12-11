# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"

  config.vm.define "db-1" do |db|
    db.vm.network "forwarded_port", guest: 3306, host: 3306
    db.vm.network "private_network", ip: "192.168.1.10"
  end

  config.vm.define "db-2" do |db|
    db.vm.network "forwarded_port", guest: 3306, host: 3307
    db.vm.network "private_network", ip: "192.168.1.11"
  end
end
