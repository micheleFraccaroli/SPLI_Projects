#!/bin/bash
tc qdisc del dev lo root

tc qdisc add dev lo root handle 1: htb default 12
tc class add dev lo parent 1: classid 1:1 htb rate 100kbps ceil 100kbps 
tc class add dev lo parent 1:1 classid 1:10 htb rate 30kbps ceil 100kbps
tc class add dev lo parent 1:1 classid 1:11 htb rate 10kbps ceil 100kbps
tc class add dev lo parent 1:1 classid 1:12 htb rate 60kbps ceil 100kbps