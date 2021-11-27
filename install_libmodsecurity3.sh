#!/bin/bash

##
# Install libmodsecurity3
##

apt-get -y install gcc make build-essential autoconf automake libtool \
	libcurl4-openssl-dev liblua5.3-dev libfuzzy-dev ssdeep \
	gettext pkg-config libpcre3 libpcre3-dev libxml2 libxml2-dev \
	libcurl4 libgeoip-dev libyajl-dev doxygen libmaxminddb-dev git

modsec_dir="/usr/local/src/ModSecurity"
if [ ! -d "$modsec_dir" ]
then
	echo "Cloning and configuring ModSecurity! This may take a while, don't close the terminal..."
	git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity $modsec_dir
	cd $modsec_dir
	git submodule init
	git submodule update
	./build.sh
	./configure

	make -j`nproc`
	make install
	echo "Cloned and configured ModSecurity from GitHub..."
else
	echo "You already have ModSecurity installed! Skipping step..."
fi
