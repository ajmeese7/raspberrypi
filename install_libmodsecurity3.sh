#!/bin/bash

##
# Install libmodsecurity3
##

apt-get -y install gcc make build-essential autoconf automake libtool \
        libcurl4-openssl-dev liblua5.3-dev libfuzzy-dev ssdeep \
        gettext pkg-config libpcre3 libpcre3-dev libxml2 libxml2-dev \
        libcurl4 libgeoip-dev libyajl-dev doxygen libmaxminddb-dev git

if [ ! -d "$modsec_dir" ];
then
        echo "Cloning and configuring ModSecurity! This may take a while, don't close the terminal..."        git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity $m>        cd $modsec_dir
        git submodule init > /dev/null
        git submodule update > /dev/null
        ./build.sh > /dev/null
        ./configure > /dev/null

        # the number must be <= the number of cores your machine possesses,
        # so my command defaults to a maximum of 1 less than the total number of cores;
        # this is unless your machine only has 1 core, in which case it will use that core
        max_num_cores=`getconf _NPROCESSORS_ONLN`-1
        make -j$(( $max_num_cores < 1 ? 1 : $max_num_cores )) > /dev/null
        make install > /dev/null
        echo "Cloned and configured ModSecurity from GitHub..."
else
        echo "You already have ModSecurity installed! Skipping step..."
fi
