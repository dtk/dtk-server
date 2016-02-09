#!/bin/bash
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
#set -x

# Output repo directory:
output_dir=$1
dtk_server=$2
dtk_repo_manager=$3
dtk_repoman_url=$4

dtk_service_module_url="internal--sm--dtk"
dtk_component_module_url_prefix="internal--cm--"

apt_url="apt"
common_user_url="common_user"
dtk_url="dtk"
dtk_activemq_url="dtk_activemq"
dtk_addons_url="dtk_addons"
dtk_client_url="dtk_client"
dtk_java_url="dtk_java"
dtk_nginx_url="dtk_nginx"
dtk_postgresql_url="dtk_postgresql"
dtk_server_url="dtk_server"
dtk_thin_url="dtk_thin"
dtk_user_url="dtk_user"
gitolite_url="gitolite"
logrotate_url="logrotate"
nginx_url="nginx"
rvm_url="rvm"
stdlib_url="stdlib"
sysctl_url="sysctl"
passenger_url="dtk_passenger"
vcsrepo_url="vcsrepo"
docker_url="docker"
dtk_repo_manager_url="dtk_repo_manager"

dtk_modules=()
dtk_modules+=($apt_url)
dtk_modules+=($common_user_url)
dtk_modules+=($dtk_url)
dtk_modules+=($dtk_activemq_url)
dtk_modules+=($dtk_addons_url)
dtk_modules+=($dtk_client_url)
dtk_modules+=($dtk_java_url)
dtk_modules+=($dtk_nginx_url)
dtk_modules+=($dtk_postgresql_url)
dtk_modules+=($dtk_server_url)
dtk_modules+=($dtk_thin_url)
dtk_modules+=($dtk_user_url)
dtk_modules+=($gitolite_url)
dtk_modules+=($logrotate_url)
dtk_modules+=($nginx_url)
dtk_modules+=($rvm_url)
dtk_modules+=($stdlib_url)
dtk_modules+=($sysctl_url)
dtk_modules+=($passenger_url)
dtk_modules+=($vcsrepo_url)
dtk_modules+=($docker_url)

# Add server related dtk modules
cd $output_dir && git clone $dtk_server && cd server && git submodule init && git submodule update
for module in ${dtk_modules[@]}; do
	#cd dtk_modules/$module
	#git fetch && git merge origin/master
  git subtree pull --prefix dtk_modules/${module} ${dtk_repoman_url}:${dtk_component_module_url_prefix}${module} master --squash -m "Updated module ${module}"
	#cd ../..
done
git subtree pull --prefix dtk_modules/${dtk_service_module_url} ${dtk_repoman_url}:${dtk_service_module_url} master --squash -m "Updated dtk service module"
git add .; git commit -m "Adding latest updates for dtk modules"; git push origin master
cd ../../..

# Add repoman related dtk modules
cd $output_dir && git clone $dtk_repo_manager && cd repo_manager && git submodule init && git submodule update
cd dtk_modules/$dtk_repo_manager_url
git fetch && git merge origin/master
