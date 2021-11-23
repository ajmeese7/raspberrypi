#!/bin/bash
# This is a helper file that can be used to later update the version
# of nginx in a way that doesn't break your ModSecurity install

##################################
# THIS FILE MUST BE RAN AS ROOT! #
##################################

# Remove all previous source code downloads
rm /usr/local/src/* -rf

# Download nginx source package
sh ./download_nginx_source.sh

# Install libmodsecurity3
sh ./install_libmodsecurity3.sh

# Download and compile ModSecurity v3 nginx connector source code
sh ./install_modsecurity_nginx.sh

apt-mark unhold nginx
apt-get upgrade nginx -y
apt-mark hold nginx
