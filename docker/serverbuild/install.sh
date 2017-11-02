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
mkdir -p /etc/puppet/

#ln -sf dtk-provisioning/modules /etc/puppet/
#cp docker/manifests /tmp/manifests
ln -sf $(pwd)/docker/addons /

chown -R ${tenant_user}:${tenant_user} /home/${tenant_user}

apt-get update
puppet apply --debug --modulepath dtk-provisioning/modules docker/manifests/stage3.pp

apt-get clean && apt-get autoclean && apt-get -y autoremove

# TEMP
sed -i '/^#.*log4j.logger.org.apache.activemq=/s/^#//' /opt/activemq/conf/log4j.properties

rm -rf /etc/puppet/modules /tmp/* /var/lib/postgresql/ /var/lib/apt/lists/* /var/tmp/* 