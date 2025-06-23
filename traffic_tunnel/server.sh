#!/bin/sh

# Assign an IP address and mask to 'tun0' interface
ifconfig tun0 mtu 1472 up 172.31.66.1 netmask 255.255.255.0 

# Enable IP forwarding
echo 1 | dd of=/proc/sys/net/ipv4/ip_forward

# Add an iptables rule to masquerade for 172.31.0.0/16
iptables -t nat -A POSTROUTING -s 172.31.0.0/16 -j MASQUERADE
