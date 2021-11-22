#!/bin/bash
# Much of his file is modified from this amazing article:
# https://www.linuxbabe.com/security/modsecurity-nginx-debian-ubuntu

### Variables that will be used throughout the program
nginx_mainline_source=/etc/apt/sources.list.d/nginx-mainline.list
modsec_dir=/usr/local/src/ModSecurity/
modsec_nginx_dir=/usr/local/src/ModSecurity-nginx
nginx_conf=/etc/nginx/nginx.conf
modsec_conf=/etc/nginx/modsec/modsecurity.conf
modsec_main_conf=/etc/nginx/modsec/main.conf
nginx_default_site=/etc/nginx/sites-available/default
modsec_logrotate=/etc/logrotate.d/modsecurity

##
# Install the lastest version of nginx
##

wget -q -O /etc/apt/trusted.gpg.d/nginx-mainline.gpg https://packages.sury.org/nginx-mainline/apt.gpg
sh -c 'echo "deb https://packages.sury.org/nginx-mainline/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/nginx-mainline.list' > /dev/null

apt-get update -y
apt-get upgrade -y
apt-get -y install apt-transport-https lsb-release ca-certificates curl \
	nginx-core nginx-common nginx nginx-full
echo "Installed the latest version of nginx..."

##
# Enable the source code repository in order to download nginx source code
##

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

##
# Download nginx source package
##

# gets the user behind the sudo call
username="${SUDO_USER:-${USER}}"
chown $username:$username /usr/local/src/ -R
mkdir -p /usr/local/src/nginx
cd /usr/local/src/nginx/

apt-get -y install dpkg-dev
apt-get source nginx

##
# Install libmodsecurity3
##

apt-get -y install gcc make build-essential autoconf automake libtool \
        libcurl4-openssl-dev liblua5.3-dev libfuzzy-dev ssdeep \
        gettext pkg-config libpcre3 libpcre3-dev libxml2 libxml2-dev \
        libcurl4 libgeoip-dev libyajl-dev doxygen libmaxminddb-dev git

if [ ! -d "$modsec_dir" ];
then
	echo "Cloning and configuring ModSecurity! This may take a while, don't close the terminal..."
	git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity $modsec_dir
	cd $modsec_dir
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

##
# Download and Compile ModSecurity v3 Nginx Connector Source Code
##

if [ ! -d "$modsec_nginx_dir" ];
then
	git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git $modsec_nginx_dir > /dev/null
	cd /usr/local/src/nginx/nginx-*
	apt-get build-dep nginx
	apt-get -qq install uuid-dev
	./configure --with-compat --add-dynamic-module=$modsec_nginx_dir > /dev/null
	make modules > /dev/null
	cp objs/ngx_http_modsecurity_module.so /usr/share/nginx/modules/
	echo "Cloned and configured ModSecurity-nginx from GitHub..."
else
	echo "You already have ModSecurity-nginx installed! Skipping step..."
fi

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
	mv /etc/nginx/modsec/$coreruleset/crs-setup.conf.example /etc/nginx/modsec/$coreruleset/crs-setup.conf
	echo "Moved your coreruleset directory to /etc/nginx/modsec..."
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
cd ~

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

systemctl --quiet reload nginx
systemctl --quiet enable nginx

# prevent nginx from updating automatically, because the ModSecurity module
# needs to be recompiled when updated. Another helper file will be coming
# soon to address this problem
apt-mark hold nginx

printf "\n##############################\n"
printf   "# FINISHED CONFIGURING NGINX #\n"
printf   "##############################\n"
