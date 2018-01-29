#!/bin/bash

# enabling the routing functionality
echo 1 >| /proc/sys/net/ipv4/ip_forward
echo 0 >| /proc/sys/net/ipv4/conf/all/rp_filter

# flush all iptables entries
iptables -t filter -F
iptables -t filter -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

# MANGLE TABLE
# initialise chains that will do the work and log the packets
iptables -t mangle -N CONNMARK1
iptables -t mangle -A CONNMARK1 -j MARK --set-mark 1
iptables -t mangle -A CONNMARK1 -j CONNMARK --save-mark
iptables -t mangle -A CONNMARK1 -j LOG --log-prefix 'iptables-mark1: ' --log-level info

iptables -t mangle -N CONNMARK2
iptables -t mangle -A CONNMARK2 -j MARK --set-mark 2
iptables -t mangle -A CONNMARK2 -j CONNMARK --save-mark
iptables -t mangle -A CONNMARK2 -j LOG --log-prefix 'iptables-mark2: ' --log-level info

iptables -t mangle -N RESTOREMARK
iptables -t mangle -A RESTOREMARK -j CONNMARK --restore-mark
iptables -t mangle -A RESTOREMARK -j LOG --log-prefix 'restore-mark: ' --log-level info

# restore the fwmark on packets that belong to an existing connection
iptables -t mangle -A PREROUTING -p tcp --dport 8080 -m state --state ESTABLISHED,RELATED -j RESTOREMARK

# if the mark is zero it means the packet does not belong to an existing connection
iptables -t mangle -A PREROUTING -p tcp --dport 8080 -m state --state NEW -m statistic --mode nth --every 2 --packet 0 -j CONNMARK1
iptables -t mangle -A PREROUTING -p tcp --dport 8080 -m state --state NEW -m statistic --mode nth --every 2 --packet 1 -j CONNMARK2


# NAT TABLE
# matching the mark number with the server assigned
iptables -t nat -A PREROUTING -p tcp --dport 8080 -m mark --mark 1  -j DNAT --to-destination 192.168.43.137
iptables -t nat -A PREROUTING -p tcp --dport 8080 -m mark --mark 2  -j DNAT --to-destination 192.168.43.176
# changign the soure address to the firewall address
#iptables -t nat -A POSTROUTING -p tcp --dport 8080 -j MASQUERADE
iptables -t nat -A POSTROUTING -p tcp --dport 8080 -j SNAT --to-source 192.168.43.77