#!/bin/bash

##
# Enable OWASP Core Rule Set
##

if [ ! -d /tmp/coreruleset ]; then mkdir /tmp/coreruleset; fi
cd /tmp/coreruleset

# https://gist.github.com/steinwaywhw/a4cd19cda655b8249d908261a62687f8#gistcomment-2736901
curl --silent "https://api.github.com/repos/coreruleset/coreruleset/releases/latest" |
    grep '"tag_name":' |
    sed -r 's/.*"([^"]+)".*/\1/' |
    xargs -I {} curl --silent -sOL "https://github.com/coreruleset/coreruleset/archive/"{}'.tar.gz'
tar xf *.tar.gz && rm *.tar.gz

coreruleset=`ls`
if [ ! -d  /etc/nginx/modsec/$coreruleset ];
then
        mv $coreruleset /etc/nginx/modsec
        mv /etc/nginx/modsec/$coreruleset/crs-setup.conf.example /etc/nginx/modsec/$coreruleset/crs-s>        echo "Moved your coreruleset directory to /etc/nginx/modsec..."
else
        echo "Your coreruleset directory is already in the right place! Skipping step..."
fi

if ! grep -q -c crs-setup.conf $modsec_main_conf;
then
        echo Include /etc/nginx/modsec/$coreruleset/crs-setup.conf >> $modsec_main_conf
        echo "Include /etc/nginx/modsec/$coreruleset/rules/*.conf" >> $modsec_main_conf
        echo "Your crs-setup.conf now includes all the rules from ModSecurity..."
else
        echo "Your crs-setup.conf already includes ModSecurity! Skipping step..."
fi

rm -rf /tmp/coreruleset

# The previous directory was deleted so we are no longer able to run commands from it
cd ~
