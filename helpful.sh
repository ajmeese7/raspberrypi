#!/bin/bash

# enables the use of the `apt-add-repository` command
apt-get install software-properties-common -y

# enables the use of the `apt-build-dep` command
sed 's/#deb-src/deb-src/' /etc/apt/sources.list
apt-get update -y

# enables the use of the nslookup tool
apt-get install bind9-utils dnsutils -y

# install the GitHub CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh
