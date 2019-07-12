# -*- mode: ruby -*-
# vi: set ft=ruby :

OPENSHIFT_RELEASE = "3.11"
OPENSHIFT_ANSIBLE_BRANCH = "release-#{OPENSHIFT_RELEASE}"
NETWORK_BASE = "192.168.150"
MASTER_HOST_ADDR = 101

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "centos/7"
  config.vm.box_check_update = false

  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.ignore_private_ip = false

  config.vm.provision "shell", inline: <<-SHELL
    /vagrant/scripts/bootstrap.sh #{OPENSHIFT_RELEASE}
  SHELL

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    vb.cpus   = "1"
  end

  # Define nodes
  (1..2).each do |i|
    config.vm.define "node0#{i}" do |node|
      node.vm.network "private_network", ip: "#{NETWORK_BASE}.#{MASTER_HOST_ADDR + i}"
      node.vm.hostname = "node0#{i}.openshift.local"

     # Vagrant's "change host name" sets the short host name.
     # Before we undo the /etc/hosts silliness (see below) let's
     # reset /etc/hostname to the *full* host name
     #
      node.vm.provision "shell",
        inline: "hostname --fqdn > /etc/hostname && hostname -F /etc/hostname"

     # Vagrant's "change host name" capability for Fedora
     # maps hostname to loopback, conflicting with hostmanager.
     # We must repair /etc/hosts
     #

      node.vm.provision "shell", inline: <<-SHELL
        sudo sed -ri 's/127\.0\.0\.1\s.*node01.openshift.local/#127.0.0.1 node01.openshift.local node01/' /etc/hosts
        sudo sed -ri 's/127\.0\.0\.1\s.*node02.openshift.local/#127.0.0.1 node02.openshift.local node02/' /etc/hosts
      SHELL

      node.vm.provision "shell" do |s|
        ssh_pub_key = File.readlines("#{Dir.home}/.ssh/id_rsa.pub").first.strip
        s.inline = <<-SHELL
          echo #{ssh_pub_key} >> /home/vagrant/.ssh/authorized_keys
          mkdir -p /root/.ssh
          touch /root/.ssh/authorized_keys
          echo #{ssh_pub_key} >> /root/.ssh/authorized_keys
        SHELL
      end

      if "#{i}" == "1"
        node.hostmanager.aliases = %w(lb.openshift.local)
      end
    end
  end

  # Define master
  config.vm.define "master", primary: true do |node|
    node.vm.network "private_network", ip: "#{NETWORK_BASE}.#{MASTER_HOST_ADDR}"
    node.vm.hostname = "master.openshift.local"
    node.hostmanager.aliases = %w(etcd.openshift.local nfs.openshift.local)

    #
    # Memory of the master node must be allocated at least 2GB in order to
    # prevent kubernetes crashed-down due to 'out of memory' and you'll end
    # up with
    # "Unable to restart service origin-master: Job for origin-master.service
    #  failed because a timeout was exceeded. See "systemctl status
    #  origin-master.service" and "journalctl -xe" for details."
    #
    # See https://github.com/kubernetes/kubernetes/issues/13382#issuecomment-154891888
    # for mor details.
    #
    node.vm.provider "virtualbox" do |vb|
      vb.memory = "3096"
    end

    node.vm.provision "shell" do |s|
      ssh_pub_key = File.readlines("#{Dir.home}/.ssh/id_rsa.pub").first.strip
      s.inline = <<-SHELL
        echo #{ssh_pub_key} >> /home/vagrant/.ssh/authorized_keys
        mkdir -p /root/.ssh
        touch /root/.ssh/authorized_keys
        echo #{ssh_pub_key} >> /root/.ssh/authorized_keys
      SHELL
    end

     # Vagrant's "change host name" sets the short host name.
     # Before we undo the /etc/hosts silliness (see below) let's
     # reset /etc/hostname to the *full* host name
     #
    node.vm.provision "shell",
      inline: "hostname --fqdn > /etc/hostname && hostname -F /etc/hostname"

     # Vagrant's "change host name" capability for Fedora
     # maps hostname to loopback, conflicting with hostmanager.
     # We must repair /etc/hosts
     #
    node.vm.provision "shell", inline: <<-SHELL
      sudo sed -ri 's/127\.0\.0\.1\s.*master.openshift.local/#127.0.0.1 master.openshift.local master/' /etc/hosts
    SHELL

    node.vm.provision "shell", inline: <<-SHELL
      hostnamectl set-hostname master.openshift.local
      /vagrant/scripts/master.sh #{OPENSHIFT_RELEASE} #{OPENSHIFT_ANSIBLE_BRANCH} #{NETWORK_BASE}
    SHELL

    # Deploy private keys of each node to master
    if File.exist?(".vagrant/machines/master/virtualbox/private_key")
      node.vm.provision "master-key", type: "file", run: "never", source: ".vagrant/machines/master/virtualbox/private_key", destination: "/home/vagrant/.ssh/master.key"
    end

    if File.exist?(".vagrant/machines/node01/virtualbox/private_key")
      node.vm.provision "node01-key", type: "file", run: "never", source: ".vagrant/machines/node01/virtualbox/private_key", destination: "/home/vagrant/.ssh/node01.key"
    end

    if File.exist?(".vagrant/machines/node02/virtualbox/private_key")
      node.vm.provision "node02-key", type: "file", run: "never", source: ".vagrant/machines/node02/virtualbox/private_key", destination: "/home/vagrant/.ssh/node02.key"
    end
  end
end
