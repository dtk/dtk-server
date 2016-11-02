#!/usr/bin/env ruby
# This RSpec script is used for creating service instance target with latest aws_images component module

require './lib/dtk_common'
require './lib/target_spec'
require './lib/workspace_spec'
require './lib/assembly_and_service_operations_spec'
require './lib/parameters_setting_spec'
require './lib/component_modules_spec'
require './lib/component_module_versions_spec'
require './lib/service_modules_spec'
require './lib/service_module_versions_spec'

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

# Stage target service, set attributes and converge

def setup_target(target, target_service_module_name, target_instance, target_service_name, aws_access_key, aws_secret_key, default_keypair)
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
end

describe 'DTK Target Service Instance update' do    
  before :all do 
    puts '**********************************', ''
  end

  context 'Delete workspace service instances in default target' do
    include_context 'Delete workspace instances in default target', target
  end

  context 'Delete default target service instance' do
    include_context 'Delete default target', target
  end

  context 'Target setup' do
    it 'creates new target and performs its setup' do
      setup_target(target, target_service_module_name, target_instance, target_service_name, aws_access_key, aws_secret_key, default_keypair)
    end
  end

  context "Create workspace" do
    include_context 'Create workspace instance', target, "workspace"
  end

  after :all do
    puts ''
  end
end