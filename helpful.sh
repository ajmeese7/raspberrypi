#!/bin/bash

# enables the use of the `apt-add-repository` command
apt install software-properties-common

# enables the use of the `apt-build-dep` command
sed 's/#deb-src/deb-src/' /etc/apt/sources.list
apt update
