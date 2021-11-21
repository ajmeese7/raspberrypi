#!/bin/bash
# Much of his file is modified from this amazing article:
# https://www.linuxbabe.com/security/modsecurity-nginx-debian-ubuntu

##
# Install the lastest version of nginx
##
curl -sSL https://packages.sury.org/nginx-mainline/README.txt | bash -x
apt update && apt upgrade -y
apt install nginx-core nginx-common nginx nginx-full -y

##
# Enable the source code repository in order to download nginx source code
##

nginx_mainline_source=/etc/apt/sources.list.d/nginx-mainline.list

# makes sure the deb-src repo isn't already in your mainline source file
if ! grep -q -c deb-src $nginx_mainline_source;
then
	nginx_binary_link=`cat $nginx_mainline_source`
	nginx_source_code_link="deb-src $(echo "$nginx_binary_link" | cut -d' ' -f 2-)"
	        # takes a substring of $nginx_binary_link
        	# `-d' '` = splits the string at the space (' ') delimeter
	        # `-f 2-` = grabs the second portion of the split through the end, because `-f` uses a 1-based index
        	# prepends 'deb-src ' to the output, which is the mainline link for your operating system version
	        # this isn't hardcoded because some devices may run on buster, others on bullseye, etc.
	echo $nginx_source_code_link >> $nginx_mainline_source
else
	echo "The 'deb-src' link is already in your mainline source file! Skipping step..."
fi

apt update

##
# Download nginx source package
##

# gets the user behind the sudo call
username="${SUDO_USER:-${USER}}"
chown $username:$username /usr/local/src/ -R
mkdir -p /usr/local/src/nginx
cd /usr/local/src/nginx/
apt install dpkg-dev

# command gives an error that can safely be ignored, so it is redirected to /dev/null
apt source nginx 2> /dev/null

##
# Install libmodsecurity3
##

modsec_dir=/usr/local/src/ModSecurity/
apt install gcc make build-essential autoconf automake libtool \
        libcurl4-openssl-dev liblua5.3-dev libfuzzy-dev ssdeep \
        gettext pkg-config libpcre3 libpcre3-dev libxml2 libxml2-dev \
        libcurl4 libgeoip-dev libyajl-dev doxygen libmaxminddb-dev git -y

# if the directory already exists, this steps have likely already been taken
if [ ! -d "$modsec_dir" ];
then
	git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity $modsec_dir
	cd $modsec_dir
	git submodule init
	git submodule update
	./build.sh

	# command gives an error that can safely be ignored, so it is redirected to /dev/null
	./configure 2> /dev/null

	# the number must be <= the number of cores your machine possesses,
	# so my command defaults to a maximum of 1 less than the total number of cores;
	# this is unless your machine only has 1 core, in which case it will use that core
	max_num_cores=`getconf _NPROCESSORS_ONLN`-1
	make -j$(( $max_num_cores < 1 ? 1 : $max_num_cores ))
	make install
else
	echo "You already have ModSecurity installed! Skipping step..."
fi

##
# Download and Compile ModSecurity v3 Nginx Connector Source Code
##

modsec_nginx_dir=/usr/local/src/ModSecurity-nginx
if [ ! -d "$modsec_nginx_dir" ];
then
	git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git $modsec_nginx_dir
	cd /usr/local/src/nginx/nginx-*
	apt build-dep nginx
	apt install uuid-dev -y
	./configure --with-compat --add-dynamic-module=$modsec_nginx_dir
	make modules
	cp objs/ngx_http_modsecurity_module.so /usr/share/nginx/modules/
else
	echo "You already have ModSecurity-nginx installed! Skipping step..."
fi

##
# Load the ModSecurity v3 Nginx Connector Module
##

nginx_conf=/etc/nginx/nginx.conf
if ! grep -q -c ngx_http_modsecurity_module $nginx_conf;
then
	# https://www.baeldung.com/linux/insert-line-specific-line-number#using-sed
	sed -i '5 i load_module modules/ngx_http_modsecurity_module.so;' $nginx_conf

	# https://stackoverflow.com/a/20026432/6456163;
	# searches for `http {` in the file and adds 1 to the line number,
	# so we can insert our custom configuration on the next line
	http_line_number=`awk '/http {/{ print NR; exit }' $nginx_conf`
	sed -i "$line_number_to_insert_config i \\\\tmodsecurity on;" $nginx_conf
	sed -i "$(( $line_number_to_insert_config + 1 )) i \\\\tmodsecurity_rules_file /etc/nginx/modsec/main.conf;" $nginx_conf
else
	echo "You have already configured nginx to include ModSecurity! Skipping step..."
fi

# ModSecurity configuration file manipulation
if [ ! -d /etc/nginx/modsec ]; then mkdir /etc/nginx/modsec; fi
modsec_conf=/etc/nginx/modsec/modsecurity.conf
cp /usr/local/src/ModSecurity/modsecurity.conf-recommended $modsec_conf
sed 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' $modsec_conf
sed 's/SecAuditLogParts ABIJDEFHZ/SecAuditLogParts ABCEFHJKZ/' $modsec_conf
sed 's/SecResponseBodyAccess On/SecResponseBodyAccess Off/' $modsec_conf

# create and populate the main.conf file
modsec_main_conf=/etc/nginx/modsec/main.conf
if [ ! -f $modsec_main_conf ];
then
	echo Include /etc/nginx/modsec/modsecurity.conf >> $modsec_main_conf
fi

# copy the Unicode mapping file
cp /usr/local/src/ModSecurity/unicode.mapping /etc/nginx/modsec/

systemctl restart nginx

##
# Enable OWASP Core Rule Set
##

# https://gist.github.com/steinwaywhw/a4cd19cda655b8249d908261a62687f8#gistcomment-2736901
if [ ! -d /tmp/coreruleset ]; then mkdir /tmp/coreruleset; fi
cd /tmp/coreruleset
curl --silent "https://api.github.com/repos/coreruleset/coreruleset/releases/latest" |
    grep '"tag_name":' |
    sed -E 's/.*"([^"]+)".*/\1/' |
    xargs -I {} curl -sOL "https://github.com/coreruleset/coreruleset/archive/"{}'.tar.gz'
tar xvf *.tar.gz && rm *.tar.gz

coreruleset=`ls`
mv $coreruleset /etc/nginx/modsec
if [ -f /etc/nginx/modsec/$coreruleset/crs-setup.conf.example ];
then
	mv /etc/nginx/modsec/$coreruleset/crs-setup.conf.example /etc/nginx/modsec/$coreruleset/crs-setup.conf
fi

if ! grep -q -c crs-setup.conf $modsec_main_conf;
then
	echo Include /etc/nginx/modsec/$coreruleset/crs-setup.conf >> $modsec_main_conf
	echo "Include /etc/nginx/modsec/$coreruleset/rules/*.conf" >> $modsec_main_conf
fi

rm -rf /tmp/coreruleset
systemctl restart nginx
systemctl enable nginx

printf "##############################\n"
printf "# FINISHED CONFIGURING NGINX #\n"
printf "##############################\n"
