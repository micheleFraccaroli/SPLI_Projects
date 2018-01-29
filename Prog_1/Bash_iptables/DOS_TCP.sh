#!/bin/bash

# flush all iptables entries
iptables -t filter -F
iptables -t filter -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

iptables -A INPUT -p tcp --dport 8080 -m state --state ESTABILISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport 8080 -m state --state NEW -m limit --limit 1/minute --limit-burst 1 -j ACCEPT
iptables -A INPUT -p tcp -j REJECT
iptables -A OUTPUT -p tcp -j ACCEPT