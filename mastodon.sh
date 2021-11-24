#!/bin/bash
# Much of this file is modified from:
# https://docs.joinmastodon.org/admin/install/

# install and configure iptables
sh ./iptables.sh

# install node.js
dpkg -r nodejs-doc
curl -fsSL https://deb.nodesource.com/setup_12.x | bash -
apt-get install nodejs -y
echo "Installed Node.js..."

# install yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
yarn_list=/etc/apt/sources.list.d/yarn.list
if [ ! -f $yarn_list ]; then
	echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee $yarn_list
fi
echo "Installed Yarn..."

# install required dependencies
apt-get update
apt-get install -y \
  imagemagick ffmpeg libpq-dev libxml2-dev libxslt1-dev file git \
  g++ libprotobuf-dev protobuf-compiler pkg-config gcc autoconf \
  bison build-essential libssl-dev libyaml-dev libreadline-dev \
  zlib1g-dev libncurses5-dev libffi-dev libgdbm-dev \
  nginx redis-server redis-tools postgresql postgresql-contrib \
  certbot python3-certbot-nginx yarn libidn11-dev libicu-dev libjemalloc-dev
dpkg --configure -a
systemctl enable postgresql --quiet
systemctl enable nginx --quiet

# create mastodon user
if [ ! $(getent passwd mastodon) ]; then
	# gecos allows us to bypass the manual entering of the user information
	adduser --disabled-login --gecos "" mastodon
else
	echo "You already have a user on your system named mastodon!"
fi

# install rbenv
apt-get remove ruby -y
su mastodon << EOF

echo "Installing rbenv..."
git clone https://github.com/rbenv/rbenv.git ~/.rbenv 2>/dev/null
cd ~/.rbenv && src/configure && make -C src
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc

# install Ruby build
echo "Installing Ruby build..."
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build 2>/dev/null

source ~/.bashrc

# install Ruby 2.7.2
echo "Installing Ruby 2.7.2 with rbenv..."
RUBY_CONFIGURE_OPTS=--with-jemalloc rbenv install 2.7.2
rbenv global 2.7.2
gem install bundler --no-document
rbenv rehash

# end of the commands ran as user 'mastodon'
EOF

# set up postgres
# https://stackoverflow.com/a/8546783/6456163
sudo -u postgres psql postgres -c "CREATE USER mastodon CREATEDB;"
echo "Created mastodon user in Postgres..."
