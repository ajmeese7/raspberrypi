#!/bin/bash

# enables the use of the `apt-add-repository` command
apt-get install software-properties-common -y

# enables the use of the `apt-build-dep` command
sed 's/#deb-src/deb-src/' /etc/apt/sources.list
apt-get update -y

# enables the use of the nslookup tool
apt-get install bind9-utils dnsutils -y
