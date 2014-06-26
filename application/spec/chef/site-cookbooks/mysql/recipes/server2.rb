#
# Cookbook Name:: mysql
# Recipe:: default
#
# Copyright 2008-2009, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "mysql::client"

case node[:platform]
when "debian","ubuntu"

  directory "/var/cache/local/preseeding" do
    owner "root"
    group "root"
    mode 0755
    recursive true
  end

  # TBD: might want to handle case where reinstalling mysql and there is already a preseed; problem is that
  # in this scenario teh following wont trigger; want to only trigger when mysql-server needs to be installed
  # can check by an only_if ls command that looks for mysql executable
  execute "preseed mysql-server" do
    command "debconf-set-selections /var/cache/local/preseeding/mysql-server.seed"
    action :nothing
  end

  template "/var/cache/local/preseeding/mysql-server.seed" do
    source "mysql-server.seed.erb"
    owner "root"
    group "root"
    mode "0600"
    notifies :run, resources(:execute => "preseed mysql-server"), :immediately
  end
end

package "mysql-server" do
  action :install
end

service "mysql" do
  service_name value_for_platform([ "centos", "redhat", "suse" ] => {"default" => "mysqld"}, "default" => "mysql")

  supports :status => true, :restart => true, :reload => true
  action :enable
end

case node[:platform]
 when "debian","ubuntu"
  execute "safe_mysql_restart" do
    cmds = ["/etc/init.d/mysql stop",
            "rm /var/lib/mysql/ib_logfile0", 
            "rm /var/lib/mysql/ib_logfile1", 
            "/etc/init.d/mysql start",
            "sleep 5"] #sleep 5 is to handle case that "/etc/init.d/mysql start" reports failure, but not really failure
    command cmds.join(';')
    action :nothing
  end
  template value_for_platform([ "centos", "redhat", "suse" ] => {"default" => "/etc/my.cnf"}, "default" => "/etc/mysql/my.cnf") do
    source "my.cnf.erb"
    owner "root"
    group "root"
    mode "0644"
    notifies :run, resources(:execute => "safe_mysql_restart"), :immediately
  end
 else
  template value_for_platform([ "centos", "redhat", "suse" ] => {"default" => "/etc/my.cnf"}, "default" => "/etc/mysql/my.cnf") do
   source "my.cnf.erb"
   owner "root"
   group "root"
   mode "0644"
   notifies :restart, resources(:service => "mysql"), :immediately
 end
end

begin
  t = resources(:template => "/etc/mysql/grants.sql")
rescue
  Chef::Log.warn("Could not find previously defined grants.sql resource")
  t = template "/etc/mysql/grants.sql" do
    source "grants.sql.erb"
    owner "root"
    group "root"
    mode "0600"
    action :create
  end
end

execute "mysql-install-privileges" do
  command "/usr/bin/mysql -u root -p#{node[:mysql][:server_root_password]} < /etc/mysql/grants.sql"
  action :nothing
  subscribes :run, resources(:template => "/etc/mysql/grants.sql")
end

case node[:platform]
  when "debian","ubuntu"
    template "/etc/mysql/debian.cnf" do
      source "debian.cnf.erb"
      owner "root"
      group "root"
      mode "0644"
      action :nothing
      subscribes :create, resources(:template => "/etc/mysql/grants.sql"),:immediately
  end
end


