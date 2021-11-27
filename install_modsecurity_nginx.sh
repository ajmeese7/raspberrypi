#!/bin/bash

##
# Download and Compile ModSecurity v3 Nginx Connector Source Code
##

modsec_nginx_dir="/usr/local/src/ModSecurity-nginx"
if [ ! -d "$modsec_nginx_dir" ]
then
	apt-get -y build-dep nginx
	git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git $modsec_nginx_dir
	cd /usr/local/src/nginx/nginx-*
	./configure --with-compat --add-dynamic-module=$modsec_nginx_dir
	make modules
	cp objs/ngx_http_modsecurity_module.so /usr/share/nginx/modules/
	echo "Cloned and configured ModSecurity-nginx from GitHub..."
else
	echo "You already have ModSecurity-nginx installed! Skipping step..."
fi
