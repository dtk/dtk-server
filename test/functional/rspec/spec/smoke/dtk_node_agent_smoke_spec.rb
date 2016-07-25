#!/usr/bin/env ruby
# This RSpec script is used for creating service instance target with latest aws_images component module

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/target_spec'
require './lib/workspace_spec'
require './lib/assembly_and_service_operations_spec'
require './lib/parameters_setting_spec'
require './lib/component_modules_spec'
require './lib/component_module_versions_spec'
require './lib/service_modules_spec'
require './lib/service_module_versions_spec'


target_name = 'target'
workspace_assembly_template = 'workspace'
module_dir = '~/dtk'
namespace = 'aws'
ec2_component_module_name = 'ec2'
image_component_module_name = 'image_aws'
image_component_module_file = 'dtk.model.yaml'
network_component_module_name = 'network_aws'
network_service_module_name = 'network'
network_service_required_modules = [image_component_module_name]

# Target specific properties
aws_access_key = ENV['AWS_ACCESS_KEY']
aws_secret_key = ENV['AWS_SECRET_KEY']
default_keypair = 'testing_use1'
security_group_name = 'default'
security_group_id = 'sg-2282f747'
subnet_id = 'subnet-af44b8d8'
target_service_name = "target-new"
target_assembly_name = 'network::single-subnet'
is_target = true

smoke_namespace = 'r8'
smoke_service_name = "node_smoke_test"
smoke_assembly_name = 'bootstrap::node_agent_smoke'

target = Common.new(target_service_name, target_assembly_name, is_target)
smoke = Common.new(smoke_service_name, smoke_assembly_name)

describe "DTK Image Lifecycle Smoke test" do
  context "Push #{namespace}:#{image_component_module_name} component-module changes" do
    include_context 'Push clone changes to server', "#{namespace}:#{image_component_module_name}", image_component_module_file
  end

  context "Stage target #{target_assembly_name}" do
    include_context "Stage", target
  end

  context "List services after stage" do    
    include_context "List services after stage", target
  end

  context "Set aws key attribute" do
    include_context "Set attribute", target, 'network_aws::iam_user[default]/aws_access_key_id', aws_access_key
  end
  
  context "Set aws secret attribute" do
    include_context "Set attribute", target, 'network_aws::iam_user[default]/aws_secret_access_key', aws_secret_key
  end

  context "Set keypair attribute" do
    include_context "Set attribute", target, 'network_aws::vpc[vpc1]/default_keypair', default_keypair
  end

  context "Set subnet id attribute" do
    include_context "Set attribute", target, 'network_aws::vpc_subnet[vpc1-public]/subnet_id', subnet_id
  end

  context "Set security group name attribute" do
    include_context "Set attribute", target, 'network_aws::security_group[vpc1-default]/group_name', security_group_name
  end

  context "Set security group id attribute" do
    include_context "Set attribute", target, 'network_aws::security_group[vpc1-default]/group_id', security_group_id
  end

  context "Converge function" do
    include_context "Converge service", target, 120
  end

  context "Set default target" do
    include_context "Set default target", target, target_service_name
  end

  context "Stage Node Agent Smoke assembly" do
    include_context "Stage with namespace", smoke, smoke_namespace
  end

  context "List services after stage" do    
    include_context "List services after stage", smoke
  end

  context "Converge function" do
    include_context "Converge", smoke
  end

  context "Delete and destroy Node Agent Smoke service" do
    include_context "Delete services", smoke
  end

  context "Delete and destroy Target service" do
    include_context "Delete services", target
  end
end
