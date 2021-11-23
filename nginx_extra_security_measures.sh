#!/bin/bash

##
# Extra security measures
##

if grep -q -c "# server_tokens" $nginx_conf;
then
        # disable leakage of information about nginx version
        sed -i 's/# server_tokens/server_tokens/' $nginx_conf
        sed -i '/server_tokens/a \
        \
        \# enable XSS-S protection\
        add_header X-XSS-Protection \"1; mode=block\";\
        \
        \# prevent clickjacking attacks\
        add_header X-Frame-Options \"SAMEORIGIN\";' $nginx_conf
        echo "Added additional security measures to your nginx.conf file..."
else
        echo "Already configured additional nginx security measures! Skipping step..."
fi

if ! grep -q -c "return 405" $nginx_default_site;
then
        sed -i '/listen \[::\]:80 default_server/a \
        \
        \# disable undesirable HTTP methods, ex. DELETE, TRACE \
        if ($request_method \!~ ^(GET|HEAD|POST)$ ) {\
                return 405;\
        }' $nginx_default_site
        echo "Blocked undesirable HTTP methods in your /etc/nginx/sites-available/default file..."
else
        echo "Already blocking undesirable HTTP methods! Skipping step..."
fi
