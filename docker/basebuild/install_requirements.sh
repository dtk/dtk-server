#!/usr/bin/env bash
#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

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
  ruby2.0 \
  lsb-release openssh-server \
  sudo curl supervisor postgresql-client libxslt-dev \
  gettext-base

mkdir -p /var/run/sshd

# install puppet
echo "gem: --no-ri --no-rdoc" > ~/.gemrc
gem2.0 install puppet -v 3.6.2

# install RVM and Ruby
RUBY_VERSION=2.2.9
curl -sSL https://get.rvm.io | bash -s master --ruby=ruby-$RUBY_VERSION
/usr/local/rvm/wrappers/default/gem install bundler --no-rdoc --no-ri

