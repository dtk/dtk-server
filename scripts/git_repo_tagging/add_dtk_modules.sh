#!/bin/bash
#set -x

# Output repo directory:
output_dir=$1

if [[ -z ${output_dir} ]]; then
  echo "output_dir argument missing"
  exit 1
fi

dtk_server="git@github.com:rich-reactor8/server.git"
dtk_service_module_url="internal--sm--dtk"
dtk_component_module_url_prefix="internal--cm--"
dtk_repoman_url="git@dtknet.servicecatalog.it"

apt_url="apt"
common_user_url="common_user"
dtk_url="dtk"
dtk_activemq_url="dtk_activemq"
dtk_addons_url="dtk_addons"
dtk_client_url="dtk_client"
dtk_java_url="dtk_java"
dtk_nginx_url="dtk_nginx"
dtk_postgresql_url="dtk_postgresql"
dtk_repo_manager_url="dtk_repo_manager"
dtk_server_url="dtk_server"
dtk_thin_url="dtk_thin"
dtk_user_url="dtk_user"
gitolite_url="gitolite"
logrotate_url="logrotate"
nginx_url="nginx"
rvm_url="rvm"
stdlib_url="stdlib"
sysctl_url="sysctl"
thin_url="thin"
vcsrepo_url="vcsrepo"

dtk_modules=()
dtk_modules+=($dtk_service_module_url)
dtk_modules+=($apt_url)
dtk_modules+=($common_user_url)
dtk_modules+=($dtk_url)
dtk_modules+=($dtk_activemq_url)
dtk_modules+=($dtk_addons_url)
dtk_modules+=($dtk_client_url)
dtk_modules+=($dtk_java_url)
dtk_modules+=($dtk_nginx_url)
dtk_modules+=($dtk_postgresql_url)
dtk_modules+=($dtk_repo_manager_url)
dtk_modules+=($dtk_server_url)
dtk_modules+=($dtk_thin_url)
dtk_modules+=($dtk_user_url)
dtk_modules+=($gitolite_url)
dtk_modules+=($logrotate_url)
dtk_modules+=($nginx_url)
dtk_modules+=($rvm_url)
dtk_modules+=($stdlib_url)
dtk_modules+=($sysctl_url)
dtk_modules+=($thin_url)
dtk_modules+=($vcsrepo_url)

cd $output_dir && git clone $dtk_server && cd server && git submodule init && git submodule update
for module in ${dtk_modules[@]}; do
	#cd dtk_modules/$module
	#git fetch && git merge origin/master
  git subtree pull --prefix dtk_modules/${module} ${dtk_repoman_url}:${dtk_component_module_url_prefix}${module} master --squash -m "Updated module ${module}"
	#cd ../..
done
git subtree pull --prefix dtk_modules/${dtk_service_module_url} ${dtk_repoman_url}:${dtk_service_module_url} master --squash -m "Updated dtk service module"
git add .; git commit -m "Adding latest updates for dtk modules"; git push origin master
