#
# Author:: Joshua Sierles <joshua@37signals.com>
# Author:: Joshua Timberman <joshua@opscode.com>
# Author:: Nathan Haneysmith <nathan@opscode.com>
# Author:: Richard Pelavin
# Cookbook Name:: nagios
# Recipe:: client
#
# Copyright 2009, 37signals
# Copyright 2009-2010, Opscode, Inc
# Copyright 2010 Richard Pelavin
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
require 'pp'
# begin
  # getting normalized information
  
  servers_host_addrs = XYZ::ArrayObject.new

  assignments = XYZ::Assembly::ComponentAssignment.get("monitoring")
  servers_node_names = assignments.find_associated_components("component[monitoring_nagios]","monitoring_server","monitored_hosts",node.name)
  unless servers_node_names.empty?
    search_query = servers_node_names.map{|n|"name:#{n}"}.join(" OR ")
    server_nodes = search(:node,search_query).map{|n|XYZ::Normalize.node(n)}
    servers_host_addrs = server_nodes.map{|n|XYZ::Network.find_interface_address(n)}
  end

  normalized_checks = XYZ::Normalize.ret_service_checks_on_node(node)
  pp [:normalized_checks,normalized_checks]

  service_check_assocs = node[:nagios][:service_check_assocs] ? node[:nagios][:service_check_assocs].to_hash : {}
  # prune service_check_assocs to only have elements from normalized_checks and graft on params from normalized_checks
  service_check_assocs.reject!{|k,v|not normalized_checks.has_key?(k)}
  normalized_checks.each do |k,v| 
    if service_check_assocs[k]
      service_check_assocs[k]["normalized_params"] = v["params"] 
      service_check_assocs[k]["attributes_to_monitor"] = v["attributes_to_monitor"] 
    end
  end
 #### using normalized info to parameterize nagios client
 
  %w{
    nagios-nrpe-server
    nagios-plugins
    nagios-plugins-basic
    nagios-plugins-standard
  }.each do |pkg|
   package pkg
  end

  service "nagios-nrpe-server" do
    action :enable
    supports :restart => true, :reload => true
  end

  # host level check instrumentation
  %w{check_mem.sh check_iostat check_memory_profiler_scout}.each{|p|load_plugin p}

  # service level check instrumentation 
  service_check_assocs.each_value do |info|
    client_info = info["client_side"]
    if client_info and info["is_custom_check"] and info["is_custom_check"] == "client_side"
      plugin_name = client_info["plugin_name"]||client_info["command_name"]||info["command_name"]
      load_plugin plugin_name do
        required_gem_packages client_info["required_gem_packages"]
        required_support_files client_info["required_support_files"]
        attributes_file client_info["attributes_file"]
        attributes_to_monitor info["attributes_to_monitor"]
      end
    end
   end

   custom_client_checks = Hash.new
   service_check_assocs.each_value do |info|
     client_info = info["client_side"]
     if client_info and info["is_custom_check"] and info["is_custom_check"] == "client_side" and client_info["command_line"]
       client_side_command_name = client_info["command_name"] || info["command_name"]
       command_line = client_info["command_line"]

       evaluated_args = XYZ::Nagios::Helper.ret_evalauted_args(client_info,info["normalized_params"])
       evaluated_args.each{|k,v|command_line.gsub!(Regexp.new("\\$#{k}\\$"),v.to_s)}
       
       custom_client_checks[client_side_command_name] = command_line
     end
   end

   template "/etc/nagios/nrpe.cfg" do
    source "nrpe.cfg.erb"
    owner "nagios"
    group "nagios"
    mode "0644"
    variables :mon_host => servers_host_addrs, :custom_client_checks => custom_client_checks
    notifies :restart, resources(:service => "nagios-nrpe-server")
  end

=begin
 rescue XYZ::ExitRecipe => e
  Chef::Log.info(e.print_form)
 rescue Exception => e
  raise e
end
=end
