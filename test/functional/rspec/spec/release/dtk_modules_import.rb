#!/usr/bin/env ruby
#This script is importing latest DTK modules from community repoman. 
#These modules will be used for dtk release deployment test

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require 'yaml'
require './lib/dtk_common'

STDOUT.sync = true

service_module = "internal:dtk"
service_module_remote = "internal/dtk"
component_module_1 = "internal/apt"
component_module_2 = "internal/dtk_user"
component_module_3 = "internal/rvm"
component_modules = ['internal:apt', 'internal:common_user', 'internal:dtk', 'internal:dtk_activemq', 'internal:dtk_addons', 'internal:dtk_client', 'internal:dtk_java', 'internal:dtk_nginx', 'internal:dtk_postgresql', 'internal:dtk_repo_manager', 'internal:dtk_server', 'internal:dtk_thin', 'internal:dtk_user', 'internal:gitolite', 'internal:logrotate', 'internal:nginx', 'internal:rvm', 'internal:stdlib', 'internal:sysctl', 'internal:thin', 'internal:vcsrepo', 'internal:epel', 'internal:dtk_passenger','internal:redis','internal:dtk_secret']

service_module_filesystem_location = '~/dtk/service_modules/internal'
component_module_filesystem_location = '~/dtk/component_modules/internal'

def delete_service_module_from_local(service_module_filesystem_location, service_module)
	deleted = false
	exists = `ls #{service_module_filesystem_location}/#{service_module}`
	exists = true if !exists.include? ("No such file or directory")
	if exists
		value = `rm -rf #{service_module_filesystem_location}/#{service_module}`
	  deleted = !value.include?("cannot remove")
	  puts "Service module #{service_module} deleted from local filesystem successfully!" if deleted == true
	else
		deleted == true
	end
  return deleted
end

def delete_component_module_from_local(component_module_filesystem_location, component_module)
	deleted = false
	exists = `ls #{component_module_filesystem_location}/#{component_module}`
	exists = true if !exists.include? ("No such file or directory")
	if exists
		value = `rm -rf #{component_module_filesystem_location}/#{component_module}`
	  deleted = !value.include?("cannot remove")
	  puts "Component module #{component_module} deleted from local filesystem successfully!" if deleted == true
	else
		deleted == true
	end
  return deleted
end

def install_service_module(service_module_remote)
	pass = false
	value = `dtk service-module install #{service_module_remote} -y`
  puts value
  pass = false if ((value.include? "ERROR") || (value.include? "exists on client"))
  puts "Import of remote service module #{service_module_remote} completed successfully!" if pass == true
  puts "Import of remote service module #{service_module_remote} did not complete successfully!" if pass == false
  return pass
end

def install_component_module(component_module_remote)
	pass = false
	value = `dtk component-module install #{component_module_remote}`
  puts value
  pass = false if ((value.include? "ERROR") || (value.include? "exists on client"))
  puts "Import of remote component module #{component_module_remote} completed successfully!" if pass == true
  puts "Import of remote component module #{component_module_remote} did not complete successfully!" if pass == false
  return pass
end

dtk_common = Common.new('', '')

service_module_deleted = dtk_common.delete_service_module(service_module)
service_module_deleted_local = delete_service_module_from_local(service_module_filesystem_location, service_module.split(":").last)
if service_module_deleted && service_module_deleted_local
	component_modules.each do |cmp|
		dtk_common.delete_component_module(cmp)
		delete_component_module_from_local(component_module_filesystem_location, cmp.split(":").last)
	end
end

install_service_module(service_module_remote)
install_component_module(component_module_1)
install_component_module(component_module_2)
install_component_module(component_module_3)

