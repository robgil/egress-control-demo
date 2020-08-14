#!/bin/bash
sudo cp /tmp/frr.conf /etc/frr/
systemctl restart frr.service
iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE # NAT the traffic for testing
iptables-save > /etc/iptables/rules.v4

