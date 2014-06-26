#
# Author:: Joshua Sierles <joshua@37signals.com>
# Author:: Joshua Timberman <joshua@opscode.com>
# Author:: Nathan Haneysmith <nathan@opscode.com>
# Author:: Richard Pelavin
# Cookbook Name:: nagios
# Recipe:: server
#
# Copyright 2009, 37signals
# Copyright 2009-2010, Opscode, Inc
# Copyright 2101 Richard Pelavin
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
require 'pp'
include_recipe "apache2"
include_recipe "apache2::mod_ssl"
include_recipe "apache2::mod_rewrite"
include_recipe "apache2::mod_auth_openid"
include_recipe "nagios::client"
begin
  # getting normalized information
  sysadmins = search(:users, 'groups:sysadmin')

  aws =  XYZ::DataBagState.safe_load(:aws, :main)
  availability_zone = node[:ec2] ? node[:ec2][:placement_availability_zone] : nil
  aws_connection = XYZ::Aws::Ec2.new(aws,availability_zone)
  aws_instances = aws_connection.describe_instances()

  assignments = XYZ::Assembly::ComponentAssignment.get("monitoring")
  monitored_hosts = assignments.find_associated_components("component[monitoring_nagios]","monitored_hosts","monitoring_server",node.name)

  normalized_nodes = XYZ::HashObject.new
  search_pattern = (monitored_hosts + [node.name]).uniq.map{|n|"name:#{n}"}.join(" OR ")
  search(:node,search_pattern).map do |n|
    normalized_nodes[n.name] = XYZ::Normalize.node(n,aws_instances,assignments)
  end
pp normalized_nodes
  host_info_list = XYZ::Normalize.ret_monitored_host_info(monitored_hosts,normalized_nodes,node.name,{:do_not_freeze_results=>true})

  #### using normalized info to parameterize nagios server

  raise XYZ::ExitRecipe.new("Nagios server's host list is empty") if host_info_list.empty?

  # TBD: right now nagios does not support a display name so have to change name ref to the display name
  host_info_list.each do |host_info|
    host_info[:alias] = host_info[:name]
    host_info[:name] = host_info[:node_display_name] if host_info.has_key?(:node_display_name)
    host_info.freeze
  end
  pp host_info_list

  service_check_assocs = node[:nagios][:service_check_assocs] ? node[:nagios][:service_check_assocs].to_hash : {}
  host_service_assocs = XYZ::HashObject.new
  nagios = XYZ::Nagios.new(service_check_assocs)
  host_info_list.each do |host_info|
    host_service_assocs[host_info[:name]] = nagios.generate_service_list(host_info)
  end

  pp host_service_assocs


  members = XYZ::ArrayObject.new
  sysadmins.each do |s|
    members << s['id']
  end

  if node[:public_domain]
    public_domain = node[:public_domain]
  else
    public_domain = node[:domain]
  end

  %w{ nagios3 nagios-nrpe-plugin nagios-images }.each do |pkg|
    package pkg
  end

  service "nagios3" do
    supports :status => true, :restart => true, :reload => true
    action [ :enable ]
  end

  nagios_conf "nagios" do
    config_subdir false
  end

  directory "#{node[:nagios][:dir]}/dist" do
    owner "nagios"
    group "nagios"
    mode "0755"
  end

  directory node[:nagios][:state_dir] do
    owner "nagios"
    group "nagios"
    mode "0751"
  end

  directory "#{node[:nagios][:state_dir]}/rw" do
    owner "nagios"
    group node[:apache][:user]
    mode "2710"
  end

  execute "archive default nagios object definitions" do
    command "mv #{node[:nagios][:dir]}/conf.d/*_nagios*.cfg #{node[:nagios][:dir]}/dist"
    not_if { Dir.glob(node[:nagios][:dir] + "/conf.d/*_nagios*.cfg").empty? }
  end

  file "#{node[:apache][:dir]}/conf.d/nagios3.conf" do
    action :delete
  end

  apache_site "000-default" do
    enable false
  end

  template "#{node[:apache][:dir]}/sites-available/nagios3.conf" do
    source "apache2.conf.erb"
    mode 0644
    variables :public_domain => public_domain
    if File.symlink?("#{node[:apache][:dir]}/sites-enabled/nagios3.conf")
      notifies :reload, resources(:service => "apache2")
    end
  end

  apache_site "nagios3.conf"

  %w{ nagios cgi }.each do |conf|
    nagios_conf conf do
      config_subdir false
    end
  end

  %w{templates timeperiods}.each do |conf|
    nagios_conf conf
  end

  nagios_conf "services" do
    variables :host_service_assocs => host_service_assocs
  end

  nagios_conf "commands" do
    variables :service_check_assocs => service_check_assocs
  end

  nagios_conf "contacts" do
    variables :admins => sysadmins, :members => members
  end

  nagios_conf "hostgroups" do
  end

  nagios_conf "hosts" do
    variables :host_info_list => host_info_list
  end


  # TBD: make contingent on whether service is on some node
  service_check_assocs.each_value do |info|
    if info["is_custom_check"] and info["is_custom_check"] == "server_side"
      load_plugin info["command_name"] do
        required_gem_packages info["required_gem_packages"]
      end
    end
  end

  # TBD: first cut; needs work
  # load ndoutils if flag captures it
  if node[:nagios][:ndoutils] and node[:nagios][:ndoutils][:enabled] 
    # TBD: way to make sure mysql is included
    # TBD: probably need preseed options for mysql
    package "ndoutils-nagios3-mysql" do
      action :install
    end

    template "/etc/default/ndoutils" do
      source "etc_default_ndoutils.erb"
      mode 0644
      notifies :restart, resources(:service => "nagios3")
      backup 0
    end

    service "ndoutils" do
      action [:enable,:start]
      not_if "pgrep ndo2db"
      notifies :restart, resources(:service => "nagios3")
      # TBD: does not if "override the subscribes signal?
      subscribes :restart, resources(:template => "/etc/default/ndoutils"), :immediately
    end
  end
  # TBD: else make sure that ndoutils damons are not running
 rescue XYZ::ExitRecipe => e
  Chef::Log.info(e.print_form)
 rescue Exception => e
  raise e
end

