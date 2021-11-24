#!/bin/bash

# install and configure iptables
sh ./iptables.sh

# install node.js
apt-get install curl -y
curl -sL https://deb.nodesource.com/setup_12.x | bash -
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
  imagemagick ffmpeg libpq-dev libxml2-dev libxslt1-dev file git-core \
  g++ libprotobuf-dev protobuf-compiler pkg-config nodejs gcc autoconf \
  bison build-essential libssl-dev libyaml-dev libreadline6-dev \
  zlib1g-dev libncurses5-dev libffi-dev libgdbm-dev \
  nginx redis-server redis-tools postgresql postgresql-contrib \
  certbot python-certbot-nginx yarn libidn11-dev libicu-dev libjemalloc-dev

# install ruby
if [ `getent passwd | grep -q -c '^mastodon:'` ]; then
	echo "Creating user mastodon..."
	adduser --disabled-login mastodon
	su - mastodon

	echo "Installing rbenv..."
	git clone https://github.com/rbenv/rbenv.git ~/.rbenv
	cd ~/.rbenv && src/configure && make -C src
	echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
	echo 'eval "$(rbenv init -)"' >> ~/.bashrc
	exec bash

	echo "Installing Rubt 2.7.2 with rbenv..."
	git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
	RUBY_CONFIGURE_OPTS=--with-jemalloc rbenv install 2.7.2
	rbenv global 2.7.2
	gem install bundler --no-document
	exit
else
	echo "You already have a user on your system named mastodon! Assuming that you already have Ruby configured for that user and skipping this step..."
fi

# set up postgres
# https://stackoverflow.com/a/8546783/6456163
if [ ! psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='mastodon'" ]; then
	psql -u postgres -c "CREATE USER mastodon CREATEDB;"
	echo "Created mastodon user in Postgres..."
else
	echo "A mastodon user already exists in Postgres! Skipping step..."
fi

