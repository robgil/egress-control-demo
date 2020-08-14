# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
    config.vm.define "host" do |host|
        host.vm.provider :libvirt do |libvirt|
            libvirt.memory = 4096
            libvirt.cpus = 8
            libvirt.qemu_use_session = false
            #libvirt.management_network_mode = "none"
            #libvirt.management_network_name = "hostmgmt"
            #libvirt.management_network_address = "172.16.20.0/24"
        end
        host.vm.network :private_network,
            :libvirt__network_name => "testnet",
            :ip => "192.168.100.100"
        host.vm.box = "debian/buster64"
        host.vm.provision "shell", inline: <<-SHELL
            apt-get install -y curl gnupg
            curl -s https://deb.frrouting.org/frr/keys.asc | sudo apt-key add -
            FRRVER="frr-7"
            echo deb https://deb.frrouting.org/frr $(lsb_release -s -c) $FRRVER > /etc/apt/sources.list.d/frr.list
            apt-get update
            apt-get install -y screen vim frr frr-pythontools
            sed -i 's/bgpd=no/bgpd=yes/' /etc/frr/daemons
            systemctl restart frr.service

            # Set up ECMP and L4 Route Hashing
            echo "net.ipv4.fib_multipath_hash_policy = 1" > /etc/sysctl.d/frr.conf
            echo "net.ipv4.fib_multipath_use_neigh = 1" >> /etc/sysctl.d/frr.conf
            sysctl -p /etc/sysctl.d/frr.conf
        SHELL
        host.vm.provision "file", source: "./host.frr", destination: "/tmp/frr.conf"
        host.vm.provision "shell", inline: <<-SHELL
            sudo cp /tmp/frr.conf /etc/frr/
            systemctl restart frr.service
            ip ro del default proto dhcp || true # Kill the default route from the management iface
        SHELL
    end
    config.vm.define "r1" do |host|
        host.vm.provider :libvirt do |libvirt|
            libvirt.memory = 2096
            libvirt.cpus = 2
            libvirt.qemu_use_session = false
        end
        host.vm.network :private_network,
            :libvirt__network_name => "testnet",
            :ip => "192.168.100.20"
        host.vm.box = "debian/buster64"
        host.vm.provision "shell", path: "./00-router.sh"
        host.vm.provision "file", source: "./router.frr", destination: "/tmp/frr.conf"
        host.vm.provision "shell", path: "./01-router.sh"
    end
    config.vm.define "r2" do |host|
        host.vm.provider :libvirt do |libvirt|
            libvirt.memory = 2096
            libvirt.cpus = 2
            libvirt.qemu_use_session = false
        end
        host.vm.network :private_network,
            :libvirt__network_name => "testnet",
            :ip => "192.168.100.21"
        host.vm.box = "debian/buster64"
        host.vm.provision "shell", path: "./00-router.sh"
        host.vm.provision "file", source: "./router.frr", destination: "/tmp/frr.conf"
        host.vm.provision "shell", path: "./01-router.sh"
    end
end
