#
# Cookbook Name:: swarm
# Recipe:: redis 
#
# Copyright 2010, Runa, Inc.
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
# app = node.run_state[:current_app]
app = Hash.new
app[:owner] = "root"
app[:group] = "root"
app[:src_dir] = "/usr/local/src"
app[:bin_dir] = "/usr/local/bin"
app[:log_dir] = "/var/log/swarm"
app[:redis] = {
    :deploy_to => "/usr/local/src/redis",
    :etc_dir => "/etc/redis",
    :log_dir => "/var/log/redis",
    :log_level => "notice",
    :version =>  "2.0.0-rc2",
    :remote_dir => "http://redis.googlecode.com/files",
    :port => "6379",
    :timeout => 3000,
    :save_load_db_dir => "/var/lib/redis",
    :sharedobjects => "no"
  }
node.set[:redis] = app[:redis]

group "redis"

user "redis" do
  comment "Random User"
  gid "redis"
  shell "/bin/false"
end

directory app[:redis][:etc_dir] do
  owner "root"
  group "root"
  mode 0755
  recursive true
end

template "#{app[:redis][:etc_dir]}/redis.conf" do
  owner "root"
  group "root"
  mode 0644
  source "redis.conf.erb"
  variables({
    :logfile => "#{app[:redis][:log_dir]}/redis-server.log",
    :port  => app[:redis][:port],
    :loglevel => app[:redis][:log_level],
    :timeout => app[:redis][:timeout],
    :save_load_db_dir => app[:redis][:save_load_db_dir],
    :remote_dir => app[:redis][:remote_dir],
    :sharedobjects => app[:redis][:sharedobjects]
  })
end

directory app[:redis][:log_dir] do
  owner "redis"
  group "redis"
  mode 0755
  recursive true
end

directory app[:redis][:save_load_db_dir] do
  owner "redis"
  group "redis"
  mode 0755
  recursive true
end

directory app[:src_dir] do
  owner "#{app[:owner]}"
  group "#{app[:group]}"
  mode 0755
  recursive true
end

remote_file "#{app[:src_dir]}/redis-#{app[:redis][:version]}.tar.gz" do
  source "#{app[:redis][:remote_dir]}/redis-#{app[:redis][:version]}.tar.gz"
  owner "#{app[:owner]}"
  group "#{app[:group]}"
  mode "0644"
  not_if do File.exists?("#{app[:src_dir]}/redis-#{app[:redis][:version]}.tar.gz") end
end

bash "Building redis from source" do
  user "#{app[:owner]}"
  cwd "#{app[:src_dir]}"
  code <<-EOH 
    tar -xvvzf #{app[:src_dir]}/redis-#{app[:redis][:version]}.tar.gz
    cd redis-#{app[:redis][:version]}
    make
  EOH
   not_if do File.exists?("#{app[:src_dir]}/redis-#{app[:redis][:version]}/redis-server")  end
end
 
bash "Installing redis" do
  user "root"
  cwd "#{app[:src_dir]}/redis-#{app[:redis][:version]}"
  code <<-EOH 
    cp redis-server redis-cli redis-benchmark #{app[:bin_dir]}
  EOH
  not_if do 
    Chef::Log.debug %q(File.exists?("#{app[:src_dir]}/redis-#{app[:redis][:version]}/redis-server"): #{File.exists?("#{app[:src_dir]}/redis-#{app[:redis][:version]}/redis-server").inspect})
    Chef::Log.debug %q(File.stat("#{app[:src_dir]}/redis-#{app[:redis][:version]}/redis-server").mtime #{File.stat("#{app[:src_dir]}/redis-#{app[:redis][:version]}/redis-server").mtime})
    Chef::Log.debug %q(File.stat("#{app[:bin_dir]}/redis-server").mtime: #{File.stat("#{app[:bin_dir]}/redis-server").mtime})
    Chef::Log.debug %q((File.stat("#{app[:src_dir]}/redis-#{app[:redis][:version]}/redis-server").mtime <= File.stat("#{app[:bin_dir]}/redis-server").mtime): #{(File.stat("#{app[:src_dir]}/redis-#{app[:redis][:version]}/redis-server").mtime <= File.stat("#{app[:bin_dir]}/redis-server").mtime)})
     File.exists?("#{app[:bin_dir]}/redis-server") && 
       (File.stat("#{app[:src_dir]}/redis-#{app[:redis][:version]}/redis-server").mtime <= File.stat("#{app[:bin_dir]}/redis-server").mtime)
  end
end

template "/etc/init.d/redis-server" do
  owner "root"
  group "root"
  mode 0755
  source "redis-server_init_d.erb"
  variables({
    :bin_dir => app[:bin_dir],
    :etc_dir  => app[:redis][:etc_dir]
  })
end

service "redis-server" do
  supports :restart => true, :reload => true
  action [ :enable, :start ]
  not_if "pgrep redis-server"
end
