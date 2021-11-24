#!/bin/bash

##
# Load the ModSecurity v3 Nginx Connector Module
##

if ! grep -q -c ngx_http_modsecurity_module $nginx_conf;
then
	# https://www.baeldung.com/linux/insert-line-specific-line-number#using-sed
	sed -i '5 i load_module modules/ngx_http_modsecurity_module.so;' $nginx_conf

	sed -i '/http {/a \
	modsecurity on;\
	modsecurity_rules_file /etc/nginx/modsec/main.conf;' $nginx_conf
	echo "nginx.conf has been configured to include ModSecurity..."
else
	echo "You have already configured nginx to include ModSecurity! Skipping step..."
fi

# ModSecurity configuration file manipulation
if [ ! -d /etc/nginx/modsec ]; then mkdir /etc/nginx/modsec; fi
cp /usr/local/src/ModSecurity/modsecurity.conf-recommended $modsec_conf
sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' $modsec_conf
sed -i 's/SecAuditLogParts ABIJDEFHZ/SecAuditLogParts ABCEFHJKZ/' $modsec_conf
sed -i 's/SecResponseBodyAccess On/SecResponseBodyAccess Off/' $modsec_conf

# create and populate the main.conf file
if [ ! -f $modsec_main_conf ];
then
	echo Include /etc/nginx/modsec/modsecurity.conf >> $modsec_main_conf
	echo "Created and configured the /etc/nginx/modsec/main.conf file..."
else
	echo "You already have a main.conf file configured! Skipping step..."
fi

# copy the Unicode mapping file
cp /usr/local/src/ModSecurity/unicode.mapping /etc/nginx/modsec/
