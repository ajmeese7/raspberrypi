#!/bin/bash
# Much of these files is abstracted from this amazing article:
# https://www.linuxbabe.com/security/modsecurity-nginx-debian-ubuntu

# adds variables required for all the scripts to bashrc, so when the
# update nginx file is ran later it has access to them
username="${SUDO_USER:-${USER}}"
if [ $username != 'root' ]; then
	bashrc=/home/$username/.bashrc
else
	bashrc=~/.bashrc
fi

if ! grep -q -c nginx_mainline_source $bashrc;
then
echo '
# See https://github.com/ajmeese7/raspberrypi for context
export nginx_mainline_source="/etc/apt/sources.list.d/nginx-mainline.list"
export modsec_dir="/usr/local/src/ModSecurity/"
export modsec_nginx_dir="/usr/local/src/ModSecurity-nginx"
export nginx_conf="/etc/nginx/nginx.conf"
export modsec_conf="/etc/nginx/modsec/modsecurity.conf"
export modsec_main_conf="/etc/nginx/modsec/main.conf"
export nginx_default_site="/etc/nginx/sites-available/default"
export modsec_logrotate="/etc/logrotate.d/modsecurity"' >> $bashrc

	. $bashrc # alternative to source
	echo "Your .bashrc has been configured with all the necessary variables..."
else
	echo "Your .bashrc already has the necessary variables configured..."
fi

# Install the lastest version of nginx
sh ./install_nginx.sh

# Download nginx source package
sh ./download_nginx_source.sh

# Install libmodsecurity3
sh ./install_libmodsecurity3.sh

# Download and compile ModSecurity v3 nginx connector source code
sh ./install_modsecurity_nginx.sh

# Load the ModSecurity v3 nginx connector module
sh ./load_modsecurity_nginx_connector.sh

# Enable OWASP core rule set
sh ./owasp_rule_set.sh

# Extra security measures
sh ./nginx_extra_security_measures.sh

# Configure logging parameters for ModSecurity
sh ./modsecurity_logging.sh

# Brotli compression algorithm with ModSecurity
sh ./modsecurity_brotli_compression.sh

# Ensure all changes made above take effect
systemctl --quiet reload nginx
systemctl --quiet enable nginx

# prevent nginx from updating automatically, because the ModSecurity module
# needs to be recompiled when updated. Another helper file will be coming
# soon to address this problem
apt-mark hold nginx

printf "\n##############################\n"
printf   "# FINISHED CONFIGURING NGINX #\n"
printf   "##############################\n"
