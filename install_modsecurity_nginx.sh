#!/bin/bash

##
# Download and Compile ModSecurity v3 Nginx Connector Source Code
##

if [ ! -d "$modsec_nginx_dir" ];
then
	git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git $modsec_nginx_dir > /dev/null
	cd /usr/local/src/nginx/nginx-*
	apt-get build-dep nginx
	apt-get -y install uuid-dev
	./configure --with-compat --add-dynamic-module=$modsec_nginx_dir > /dev/null
	make modules > /dev/null
	cp objs/ngx_http_modsecurity_module.so /usr/share/nginx/modules/
	echo "Cloned and configured ModSecurity-nginx from GitHub..."
else
	echo "You already have ModSecurity-nginx installed! Skipping step..."
fi
