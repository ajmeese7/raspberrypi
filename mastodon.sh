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
su -l mastodon << EOF

apt-get remove -y ruby
apt-get update
apt-get install -y git curl libssl-dev libreadline-dev zlib1g-dev \
	autoconf bison build-essential libyaml-dev libreadline-dev \
	libncurses5-dev libffi-dev libgdbm-dev

curl -sL https://github.com/rbenv/rbenv-installer/raw/main/bin/rbenv-installer | bash -
if ! grep -q -c rbenv ~/.bashrc; then
        echo "Adding rbenv to path..."
        echo 'export PATH=$HOME/.rbenv/bin:$PATH' >> ~/.bashrc
        echo 'eval "$(rbenv init - bash)"' >> ~/.bashrc
else
        echo "rbenv already on path..."
fi

EOF

echo "\n\nBack to root...\n\n"

su -l mastodon << EOF

. ~/.bashrc
RUBY_CONFIGURE_OPTS=--with-jemalloc rbenv install --verbose 2.7.2
rbenv global 2.7.2
gem install bundler --no-document

EOF

# set up postgres
# https://stackoverflow.com/a/8546783/6456163
sudo -u postgres psql postgres -c "CREATE USER mastodon CREATEDB;" 2>/dev/null
echo "Created mastodon user in Postgres..."

# set up mastodon
su - mastodon << EOF

git clone https://github.com/tootsuite/mastodon.git live && cd live
git checkout $(git tag -l | grep -v 'rc[0-9]*$' | sort -V | tail -n 1)
bundle config deployment 'true'
bundle config without 'development test'
bundle install -j$(getconf _NPROCESSORS_ONLN)
yarn install --pure-lockfile

# TODO: MAKE THIS NOT INTERACTIVE AND INSTEAD PRESET
RAILS_ENV=production bundle exec rake mastodon:setup

EOF

# set up nginx
cp /home/mastodon/live/dist/nginx.conf /etc/nginx/sites-available/mastodon
ln -s /etc/nginx/sites-available/mastodon /etc/nginx/sites-enabled/mastodon
# TODO ~> EDIT /etc/nginx/sites-available/mastodon TO REPLACE example.com WITH DOMAIN NAME

certbot --nginx -d example.com
cp /home/mastodon/live/dist/mastodon-*.service /etc/systemd/system/
$EDITOR /etc/systemd/system/mastodon-*.service
systemctl daemon-reload
systemctl enable --now mastodon-web mastodon-sidekiq mastodon-streaming

# SHOULD BE ABLE TO VISIT IN BROWSER AS OF HERE!
