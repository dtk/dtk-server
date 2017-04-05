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
bash /tmp/docker/basebuild/install_requirements.sh

puppet apply /tmp/docker/manifests/stage1.pp
puppet apply /tmp/docker/manifests/stage2.pp
puppet apply /tmp/docker/manifests/stage4.pp

apt-get install -y libpq-dev redis-server libicu-dev

cd /tmp
/usr/local/rvm/wrappers/default/bundle --without development --deployment --path=/var/lib/dtk-bundler-vendor

# Prevent intermittent Gitolite issues
# http://stackoverflow.com/a/2510548/15677
sed -i 's/^AcceptEnv LANG LC_\*$//g' /etc/ssh/sshd_config
# http://stackoverflow.com/questions/22547939/docker-gitlab-container-ssh-git-login-error
sed -i '/session    required     pam_loginuid.so/d' /etc/pam.d/sshd

apt-get clean && apt-get autoclean && apt-get -y autoremove

rm -rf /etc/puppet/modules /tmp/* /var/lib/postgresql/ /var/lib/apt/lists/* /var/tmp/* 