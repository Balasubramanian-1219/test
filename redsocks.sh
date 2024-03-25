#!/bin/bash

flush_ip() 
{
# Accept all traffic first to avoid ssh lockdown  via iptables firewall rules #
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Flush All Iptables Chains/Firewall rules #
iptables -F

# Delete all Iptables Chains #
iptables -X

# Flush all counters too #
iptables -Z
# Flush and delete all nat and  mangle #
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -t raw -F
iptables -t raw -X

}

flush_ip

# Create new chains for redsocks
iptables -t nat -N REDSOCKS
iptables -t nat -A REDSOCKS -d 0.0.0.0/8 -j RETURN
iptables -t nat -A REDSOCKS -d 10.0.0.0/8 -j RETURN
iptables -t nat -A REDSOCKS -d 127.0.0.0/8 -j RETURN
iptables -t nat -A REDSOCKS -d 169.254.0.0/16 -j RETURN
iptables -t nat -A REDSOCKS -d 172.16.0.0/12 -j RETURN
iptables -t nat -A REDSOCKS -d 192.168.42.0/32 -j RETURN  # VPN client 
iptables -t nat -A REDSOCKS -d 103.16.202.0/24 -j RETURN # dennis 
iptables -t nat -A REDSOCKS -d 122.165.68.0/24 -j RETURN  # larry
iptables -t nat -A REDSOCKS -d 224.0.0.0/4 -j RETURN
iptables -t nat -A REDSOCKS -d 240.0.0.0/4 -j RETURN

PORT='22,25,143,223,80,443,6001,5432,5225,5900,5901,5902,6002'

# route ip segment to specific port
iptables -t nat -A REDSOCKS -d  192.168.12.0/24 -p tcp --match multiport --dport $PORT -j REDIRECT --to-ports 12345

iptables -t nat -A OUTPUT -p tcp -j REDSOCKS

iptables -t nat -A PREROUTING -p tcp  --match multiport --dport $PORT -j REDSOCKS

notify-send "VPN Start Successfully.."

_term() {
	echo "Caught SIGTERM signal!"
	kill -TERM "$child" 2>/dev/null
	flush_ip
	notify-send "VPN stopped Successfully.."
	exit;
}

trap _term SIGTERM

sleep infinity &

child=$!
wait "$child"
