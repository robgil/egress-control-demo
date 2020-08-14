#!/bin/bash
apt-get install -y curl gnupg
curl -s https://deb.frrouting.org/frr/keys.asc | sudo apt-key add -
FRRVER="frr-7"
echo deb https://deb.frrouting.org/frr $(lsb_release -s -c) $FRRVER > /etc/apt/sources.list.d/frr.list
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y screen vim frr frr-pythontools iptables-persistent
sed -i 's/bgpd=no/bgpd=yes/' /etc/frr/daemons
systemctl restart frr.service
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/forward.conf
sysctl -p /etc/sysctl.d/forward.conf

