#!/bin/bash
# Much of these files is abstracted from this amazing article:
# https://www.linuxbabe.com/security/modsecurity-nginx-debian-ubuntu

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
