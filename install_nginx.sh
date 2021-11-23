#!/bin/bash

##
# Install the lastest version of nginx
##

wget -q -O /etc/apt/trusted.gpg.d/nginx-mainline.gpg https://packages.sury.org/nginx-mainline/apt.gpg
sh -c 'echo "deb https://packages.sury.org/nginx-mainline/ $(lsb_release -sc) main" > /etc/apt/source>

apt-get update -y
apt-get upgrade -y
apt-get -y install apt-transport-https lsb-release ca-certificates curl \
        nginx-core nginx-common nginx nginx-full
echo "Installed the latest version of nginx..."

# Enable the source code repository in order to download nginx source code
nginx_binary_link=`cat $nginx_mainline_source`
nginx_source_code_link="deb-src $(echo "$nginx_binary_link" | cut -d' ' -f 2-)"
        # takes a substring of $nginx_binary_link
        # `-d' '` = splits the string at the space (' ') delimeter
	# `-f 2-` = grabs the second portion of the split through the end, because `-f` uses a 1-based index
       	# prepends 'deb-src ' to the output, which is the mainline link for your operating system version
        # this isn't hardcoded because some devices may run on buster, others on bullseye, etc.

echo $nginx_source_code_link >> $nginx_mainline_source
echo "Uncommented the 'deb-src' line in your nginx-mainline.list file..."
apt-get update -y
