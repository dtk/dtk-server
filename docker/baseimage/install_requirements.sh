#!/usr/bin/env bash

set -x

# add git-core ppa
apt-get -y update -q
apt-get -y install software-properties-common
yes | add-apt-repository ppa:git-core/ppa

# update and install packages
apt-get -y update -q
apt-get install -y language-pack-en
locale-gen en_US.UTF-8
apt-get install -y \
  apt-transport-https ca-certificates \
  git cron \
  ruby ruby-dev \
  lsb-release openssh-server \
  sudo curl supervisor postgresql-client libxslt-dev \
  gettext-base

mkdir -p /var/run/sshd

# install puppet
echo "gem: --no-ri --no-rdoc" > ~/.gemrc
gem install puppet -v 3.6.2

# install RVM and Ruby
RUBY_VERSION=1.9.3-p484
curl -sSL https://get.rvm.io | bash -s master --ruby=ruby-$RUBY_VERSION
/usr/local/rvm/wrappers/default/gem install bundler --no-rdoc --no-ri

# cleanup
apt-get clean && apt-get -y autoremove && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*