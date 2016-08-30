#!/usr/bin/env ruby
# This is DTK Server smoke test used for execution in DTK Release process

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/parameters_setting_spec'
require './lib/component_modules_spec'
require './lib/component_module_versions_spec'
require './lib/service_modules_spec'
require './lib/service_module_versions_spec'
require './lib/target_spec'

catalog_username = "dtk16"
catalog_password = "password"
service_name = 'dtk_release_smoke_test'
assembly_name = 'bootstrap::node_with_params'
os_templates = ['trusty','amazon']
os_attribute = 'os_identifier'
instance_size = 't1.micro'
instance_size_attribute = 'instance_size'
node_name = 'node1'
component_module_name = "test_module"
local_component_module_name = 'dtk16:test_module'
remote_component_module_name = 'dtk16/test_module'
component_module_version = "0.0.1"
service_module_name = "bootstrap"
service_module_version = "0.0.1"
local_service_module_name = 'dtk16:bootstrap'
remote_service_module_name = 'dtk16/bootstrap'
namespace = 'dtk16'
local_default_namespace = 'dtk16'
component_module_filesystem_location = "~/dtk/component_modules"

ec2_component_module_name = 'ec2'
image_component_module_name = 'image_aws'
network_component_module_name = 'network_aws'
network_service_module_name = 'network'

# Target specific properties
aws_access_key = ENV['AWS_ACCESS_KEY']
aws_secret_key = ENV['AWS_SECRET_KEY']
default_keypair = 'testing_use1'
security_group_name = 'default'
security_group_id = 'sg-2282f747'
subnet_id = 'subnet-af44b8d8'
target_service_name = 'target'
target_assembly_name = 'network::single-subnet'
is_target = true

target = Common.new(target_service_name, target_assembly_name, is_target)
dtk_common = Common.new(service_name, assembly_name)

describe "DTK Server smoke test release" do

  before(:all) do
    puts "*****************************",""
  end

  context "Set catalog credentials" do
    include_context "Set catalog credentials", dtk_common, catalog_username, catalog_password
  end

  context "Set default namespace" do
    include_context "Set default namespace", dtk_common, local_default_namespace
  end

  # Part where we set default target
  context "Import ec2 target component" do
    include_context "Import component module", ec2_component_module_name
  end

  context "Create new component module version" do
    include_context 'Create component module version', dtk_common, local_default_namespace + ":" + ec2_component_module_name, component_module_version
  end

  context "Import image target component" do
    include_context "Import component module", image_component_module_name
  end

  context "Import network target component" do
    include_context "Import component module", network_component_module_name
  end

  context "Import network target service module" do
    include_context "Import service module", network_service_module_name
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
    include_context "Converge service", target, 30
  end

  context "Set default target" do
    include_context "Set default target", target, target_service_name
  end

  # Part where actual smoke test starts
  context "Import new component module function" do
    include_context "Import component module", component_module_name
  end

  context "Create new component module version" do
    include_context 'Create component module version', dtk_common, local_component_module_name, component_module_version
  end

  context "Import new service module function" do
    include_context "Import service module", service_module_name
  end

  context "Create new service module version" do
    include_context 'Create service module version', dtk_common, local_service_module_name, service_module_version
  end

  context "Publish versioned component module to #{namespace} namespace" do
    include_context "Publish versioned component module", dtk_common, local_component_module_name, remote_component_module_name, component_module_version
  end

  context "Publish versioned component module to #{namespace} namespace" do
    include_context "Publish versioned component module", dtk_common, local_default_namespace + ":" + ec2_component_module_name, local_default_namespace + "/" + ec2_component_module_name, component_module_version
  end
 
  context "Publish versioned service module to #{namespace} namespace" do
    include_context "Publish versioned service module", dtk_common, local_service_module_name, remote_service_module_name, service_module_version
  end

  context "Get component module components list" do
    include_context "Get component module components list", dtk_common, local_component_module_name
  end

  os_templates.each do |os|
    context "Stage service function on #{assembly_name} assembly" do
      include_context "Stage", dtk_common
    end

    context "List services after stage" do    
      include_context "List services after stage", dtk_common
    end

    context 'Set image attribute function' do
      include_context 'Set attribute', dtk_common, 'node1/image', os
    end

    context "Converge function" do
      include_context "Converge service", dtk_common, 30
    end

    context "Delete and destroy service function" do
      include_context "Delete services", dtk_common
    end
  end

  #context "Delete target #{target_service_name}" do
  #  it "deletes target instance" do
  #    target_service_name = 'target'
  #    target_assembly_name = 'network::single-subnet'
  #    target_to_delete = Common.new(target_service_name, target_assembly_name)
  #    target_deleted = target_to_delete.delete_target(target_service_name)
  #    target_deleted.should eq(true)
  #  end
  #end

  context "Delete service module function" do
    include_context 'Delete all service module versions', dtk_common, local_service_module_name
  end

  #context "Delete service module function" do
  #  include_context 'Delete all service module versions', dtk_common, local_default_namespace + ":" + network_service_module_name
  #end

  context "Delete component module function" do
    include_context 'Delete all component module versions', dtk_common, local_component_module_name
  end

  #context "Delete component module function" do
  #  include_context 'Delete all component module versions', dtk_common, local_default_namespace + ":" + ec2_component_module_name
  #end

  #context "Delete component module function" do
  #  include_context 'Delete all component module versions', dtk_common, local_default_namespace + ":" + image_component_module_name
  #end

  #context "Delete component module function" do
  #  include_context 'Delete all component module versions', dtk_common, local_default_namespace + ":" + network_component_module_name
  #end

  context "Delete #{component_module_name} component module version #{component_module_version} from remote" do
    include_context "Delete component module from remote repo", component_module_name, namespace
  end

  context "Delete #{component_module_name} component module base version from remote" do
    include_context "Delete component module from remote repo", component_module_name, namespace
  end

  #context "Delete #{ec2_component_module_name} component module version #{component_module_version} from remote" do
  #  include_context "Delete component module from remote repo", ec2_component_module_name, namespace
  #end

  #context "Delete #{ec2_component_module_name} component module base version from remote" do
  #  include_context "Delete component module from remote repo", ec2_component_module_name, namespace
  #end

  #context "Delete #{service_module_name} service module version #{service_module_version} from remote" do
  #  include_context "Delete service module from remote repo", service_module_name, namespace
  #end

  #context "Delete #{service_module_name} service module base version from remote" do
  #  include_context "Delete service module from remote repo", service_module_name, namespace
  #end

  after(:all) do
    puts "", ""
  end
end