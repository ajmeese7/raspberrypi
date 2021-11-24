#!/bin/bash

##
# Brotli compression algorithm with ModSecurity
##

apt -y install libnginx-mod-brotli
if ! grep -q -c brotli $nginx_conf; then
	sed -i '/gzip_types/a\
	\
	\##\
	\# Brotli Settings\
	\##\
	\
	brotli on;\
	brotli_comp_level 6;\
	brotli_static on;\
	brotli_types application/atom+xml application/javascript application/json\
		application/rss+xml application/vnd.ms-fontobject application/x-font-opentype\
		application/x-font-truetype application/x-font-ttf application/x-javascript\
		application/xhtml+xml application/xml font/eot font/opentype font/otf\
		font/truetype image/svg+xml image/vnd.microsoft.icon image/x-icon\
		image/x-win-bitmap text/css text/javascript text/plain text/xml;' $nginx_conf
	echo "Added Brotli compression support to nginx.conf..."
else
	echo "Brotli compression support already enabled! Skipping step..."
fi
