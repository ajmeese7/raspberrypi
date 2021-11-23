#!/bin/bash

##
# Configure logging parameters for ModSecurity
##

if [ ! -f $modsec_rotate ]; then
sed -i "$ a\
/var/log/modsec_audit.log\
{\
        rotate 30\
        daily\
        missingok\
        compress\
        delaycompress\
        notifempty\
}" $modsec_rotate
echo "Your logrotate folder now includes rules on how to handle ModSecurity logs..."
else
        echo "Your logrotate folder already has rules for ModSecurity logs! Skipping step..."
fi
