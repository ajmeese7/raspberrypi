#!/bin/bash

##
# Download nginx source package
##

# gets the user behind the sudo call
username="${SUDO_USER:-${USER}}"
chown $username:$username /usr/local/src/ -R
mkdir -p /usr/local/src/nginx
cd /usr/local/src/nginx/

apt-get -y install dpkg-dev
apt-get source nginx
