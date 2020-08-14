# ECMP Multiple Default Gateways Demo
One of the biggest challenges in cloud environments is having redundant gateways to the internet. This is especially apparent when you want to control egress to the internet through some form of security appliances.

## Assumptions
- Cloud provider route tables have IGWs and other routes removed
  - Local route of the subnet would be the only route remaining
- Security Groups / IPTables allow BGP
  - These should restrict BGP/traffic to only the BGP routers

## Requirements
- Kernel 4.19+
- FRR 7.3.1
- IPTables
- Vagrant (for the demo)
- LibVirt (for the demo)

# Configuration
The only pre-requisite is creating an internal network for the `host` to have connectivity to `r1` and `r2`. Create a network with `Forwarding Mode: Open`. This mode will turn off all iptables/nat that would normally be added to a network. Set the IP Range to 192.168.100.0/24, with DHCP `Disabled`. Call it `testnet` to coincide with the Vagrant configuration.

After that, just bring it up.
```
vagrant up host r1 r2
```

# Is it working?
If its working (and the default route from the management network is removed), you'll see something like the following.

```
root@buster:~# ip ro sh
default proto bgp metric 20 
	nexthop via 192.168.100.20 dev ens6 weight 1 
	nexthop via 192.168.100.21 dev ens6 weight 1 
192.168.100.0/24 dev ens6 proto kernel scope link src 192.168.100.100 
192.168.121.0/24 dev ens5 proto kernel scope link src 192.168.121.53 
192.168.121.1 dev ens5 proto dhcp scope link src 192.168.121.53 metric 1024 
```
Note the two routes with equal weight.

# How does this work?
The magic, which didn't exist in the linux kernel until 4.17 and with updates in 4.19 is the hashing algorithms that were added. With L4 hashing, we avoid dropping connections due to asymmetric routing. Each IP/Port is hashed to a specific path and will consistently stay on that path. If a router goes down, the connections will get re-hashed. Theoretically 1/2 the connections would disconnect, but all subsequent connections would go out the remaining router.

# But I don't want to configure 100s of neighbors!
The router is configured with Dynamic BGP Peers. The part that does that is the following

```
 bgp listen range 192.168.100.96/27 peer-group fabric
```

With this configuration, you can set the whole VPC supernet if you wanted to. No individual host neighbor configurations.

I should note that as of this writing [support](https://phabricator.vyos.net/T1875) is not yet available in VyOS. This would require FRR if staying OSS.

# Cloud Considerations
There are a few caveats with nuking default gateways in a cloud provider.

- Breaks Subnet to Subnet routing
  - This can be overcome by adding a static route to the supernet in the FRR config or via CM (Configuration Management). This will be uniqe per subnet, but fairly trivial to automate. All subnet and supernet information is available in the metadata.
```
curl 169.254.169.254/latest/meta-data/network/interfaces/macs/xx:xx:xx:xx:xx:xx/vpc-ipv4-cidr-block
curl 169.254.169.254/latest/meta-data/network/interfaces/macs/xx:xx:xx:xx:xx:xx/subnet-ipv4-cidr-block
```
- But I'm multihoming my hosts!
  - Stop. There is no reason for this. No really, are you serious?
- Cloud DHCP adds a default route which is a higher priority than BGP routes!
  - True. This behavior can be removed in the dhclient.conf. (remove `routers` from the request section)
- VPC Peering breaks
  - Adding the static route for the supernet will get this working appopriately. The only thing we don't want, is blanket default routes coming from AWS.
- PrivateLink Breaks
  - Same as above. Add the static route for the supernet to the gateway of the subnet. 
- I can't access my hosts from outside the subnet!
  - This would only happen if the static route was missing
- I need to access my hosts from other VPCs
  - Fantastic! Let's use some egress controls. Just add those routes to the routers and advertise them to the hosts.

# Actually controlling egress
I didn't put any "control" in to this demo, but here are some examples of things you could configure on the routers to restrict/gate egress to the internet. 
- Transparent Squid Proxy
- IPTables rules

Obviously in a cloud setting, your routers will need a path out to the internet (IGW, DX, TGW, etc)
