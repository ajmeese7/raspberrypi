#!/bin/bash
# This file is modified from:
# https://docs.joinmastodon.org/admin/prerequisites/

##
# Install and configure iptables
##

apt-get update && apt-get upgrade -y
apt-get install iptables-persistent -y

# whitelists only SSH, HTTP, and HTTPS ports
iptables_conf=/etc/iptables/rules.v4
if [ ! -f $iptables_conf ]; then
echo '
*filter

#  Allow all loopback (lo0) traffic and drop all traffic to 127/8 that doesn'\''t use lo0
-A INPUT -i lo -j ACCEPT
-A INPUT ! -i lo -d 127.0.0.0/8 -j REJECT

#  Accept all established inbound connections
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

#  Allow all outbound traffic - you can modify this to only allow certain traffic
-A OUTPUT -j ACCEPT

#  Allow HTTP and HTTPS connections from anywhere (the normal ports for websites and SSL).
-A INPUT -p tcp --dport 80 -j ACCEPT
-A INPUT -p tcp --dport 443 -j ACCEPT

#  Allow SSH connections
#  The -dport number should be the same port number you set in sshd_config
-A INPUT -p tcp -m state --state NEW --dport 22 -j ACCEPT

#  Allow ping
-A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT

#  Log iptables denied calls
-A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables denied: " --log-level 7

#  Reject all other inbound - default deny unless explicitly allowed policy
-A INPUT -j REJECT
-A FORWARD -j REJECT

COMMIT
' >> $iptables_conf

	# with iptables-persistent, that configuration will be loaded at boot time.
	# but since we are not rebooting right now, we need to load it manually for the first time.
	iptables-restore < $iptables_conf
	echo "Configured iptables-persistent..."
else
	echo "You already have an iptables rules.v4 file! Skipping step..."
fi
