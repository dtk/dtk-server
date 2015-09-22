#!/usr/bin/env ruby
# Create Provider and Target, pull r8:bootstrap from remote repo.
require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/service_modules_spec'

dtk_common = Common.new('', '')
config = YAML::load(File.open("./config/release.yml"))
provider_name="test_provider"
keypair_name="testing_use1"
sg_name="default"
iaas_type="ec2"
target_type="ec2_classic"
target_region="us-east-1"
provider_id=provider_name
target_name="test_target"
service_module="r8/bootstrap"
local_module="bootstrap"
catalog_user="docker-credentials"
catalog_pass="r8server"
repo_user="dtk17-docker-client"
namespace="r8"
cmps=["dtk","dtk_activemq","dtk_java","logrotate","stdlib"]



# Create new provider
provider_status=dtk_common.send_request('/rest/target/create_provider',  iaas_properties: {keypair: keypair_name, security_group: sg_name, key: config['properties']['aws_access_key_id'], secret: config['properties']['aws_secret_access_key']}, provider_name: provider_name, iaas_type: iaas_type, no_bootstrap: true)

if provider_status['status']=='ok' 
	puts "Provider #{provider_name} created!"
else
	puts "Failed to create provider #{provider_name}."
end

# Create new target
target_status=dtk_common.send_request('/rest/target/create', type: target_type, provider_id: provider_name, iaas_properties: { region: target_region }, target_name: target_name)
if target_status['status']=='ok'  
	puts "Target #{target_name} created!"
else
	puts "Failed to create target #{target_name}."
end

# Set default target
default_target_status=dtk_common.send_request('/rest/target/set_default', target_id: target_name)
if default_target_status['status']=='ok'  
	puts "Target #{target_name} set as default target!"
else
	puts "Failed to set #{target_name} as default target."
end

#set catalog credentials and ssh key
credentials_status=dtk_common.send_request('/rest/account/set_catalog_credentials', username: catalog_user, password: catalog_pass, validate: true)
ssh_key_status=dtk_common.send_request('/rest/account/add_user_direct_access', rsa_pub_key: dtk_common.ssh_key, username: repo_user, first_registration: false)


`dtk service-module install #{service_module} --update-none -y`
=begin


# install component modules
cmps.each do |cmp|
	cmp_status=dtk_common.send_request('/rest/component_module/import', remote_module_name: "#{namespace}/#{cmp}", local_module: cmp, rsa_pub_key: dtk_common.ssh_key)
end


# install r8:bootstrap service module
module_status=dtk_common.send_request('/rest/service_module/import', remote_module_name: service_module, local_module_name: local_module, rsa_pub_key: dtk_common.ssh_key, do_not_raise: true)

if module_status['status']=='ok' 
	puts "Module #{service_module} pulled from remote repo!"
else
	puts "Failed to pull #{service_module} from remote repo."
end

=end
