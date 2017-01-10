#!/usr/bin/env ruby
require './lib/dtk_common'

config = YAML::load(File.open("./config/release.yaml"))
service_module="r8/bootstrap"
local_module="bootstrap"
catalog_user="docker-credentials"
catalog_pass="password"
repo_user="dtk17-docker-client"
namespace="r8"

# Target specific properties
target_service_module = 'aws/network'
target_service_module_name = 'aws:network'
aws_access_key = ENV['AWS_ACCESS_KEY']
aws_secret_key = ENV['AWS_SECRET_KEY']
default_keypair = 'testing_use1'
target_service_name = 'target'
target_instance = 'network-target'
target_assembly_name = 'network::target-v1.0.2'
is_target = true
target_location = "/tmp/network"

target = Common.new(target_service_name, target_assembly_name, is_target)

# Set catalog credentials and ssh key
credentials_status=target.send_request('/rest/account/set_catalog_credentials', username: catalog_user, password: catalog_pass, validate: true)
ssh_key_status=target.send_request('/rest/account/add_user_direct_access', rsa_pub_key: target.ssh_key, username: repo_user, first_registration: false)

# Install aws:network service module with required component modules
system("dtk module install -d #{target_location} -y #{target_service_module}")

# Stage target service, set attributes and converge
target_staged = target.stage_service_instance(target_service_module_name, target_instance)
if target.check_if_service_exists(target.service_id)
  puts "Set attributes for staged target..."
  set_attributes_array = []
  set_attributes_array << target.set_attribute(target.service_id, 'identity_aws::credentials/aws_access_key_id', aws_access_key)
  set_attributes_array << target.set_attribute(target.service_id, 'identity_aws::credentials/aws_secret_access_key', aws_secret_key)
  set_attributes_array << target.set_attribute(target.service_id, 'network_aws::vpc[vpc1]/default_keypair', default_keypair)
  if !set_attributes_array.include? false
    service_converged = target.converge_service(target.service_id, 10)
    if service_converged == true
      puts "#{target_service_name} service deployed!"
      target.set_default_target(target_service_name)
    else
      fail "[ERROR] #{target_service_name} service was not deployed successfully!"
    end
  else
    fail "[ERROR] Some of the attributes are not set correctly. Will not proceed with converge process!"
  end
else
  fail "[ERROR] Failed to stage target #{target_service_name}"
end
