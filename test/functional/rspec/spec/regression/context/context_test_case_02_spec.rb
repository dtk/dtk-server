#!/usr/bin/env ruby
require './lib/dtk_cli_spec'
require './lib/dtk_common'

# context specific properties
service_location = '~/dtk/'
context_location = "/tmp/network"
context_module = 'aws/aws_vpc'
context_assembly_template = 'discover_using_node_profile'
context_service_name = 'context_test_case_02'
context_name = 'discover_using_node_profile'
context_version = 'master'

# context attributes
default_keypair = 'testing_use1'
vpc_id = 'vpc-d9946ba0'
security_group_name = 'r8_test_security_group'
subnet_id = 'subnet-99c00fb5'

# Module specific properties
initial_module_location = "./spec/regression/context/resources/test_module_02_dtk.module.yaml"
module_location = '/tmp/dtk_test_module_02'
module_name = 'test/context_test_module_02'
assembly_name = 'test_assembly'
service_name = 'dtk_test_module_02'

dtk_common = Common.new('', '')

describe "(Context) Test Case 02: Specified existing subnet id, vpc and security group name" do
  before(:all) do
    puts '********************************************************************************', ''
    # Install aws:network module with required dependency modules
    system("rm -rf /tmp/network && mkdir /tmp/network")
    system("dtk module install --update-deps -d #{context_location} #{context_module}")
  end

  context "List assemblies contained in this module" do
    include_context "List assemblies", context_module, context_assembly_template, dtk_common
  end

  context "Stage context from module" do
    include_context "Stage context from module", context_module, context_location, context_name, context_service_name
  end

  context "Set attribute for default keypair" do
    include_context "Set attribute", service_location, context_service_name, 'ec2::profile[default]/key_name', default_keypair
  end

  context "Set attribute for vpc" do
    include_context "Set attribute", service_location, context_service_name, 'aws_vpc::subnet[default]/vpc_id', vpc_id
  end

  context "Set attribute for subnet length" do
    include_context "Set attribute", service_location, context_service_name, 'aws_vpc::subnet[default]/subnet_id', subnet_id
  end

  context "Set attribute for security group name" do
    include_context "Set attribute", service_location, context_service_name, 'aws_vpc::security_group[default]/security_group_name', security_group_name
  end

  context "Converge service instance" do
    include_context "Converge service instance", service_location, dtk_common, context_service_name
  end

  context "Setup initial module on filesystem" do
    include_context "Setup initial module on filesystem", initial_module_location, module_location
  end

  context "Install module" do
    include_context "Install module", module_name, module_location
  end

  context "List assemblies contained in this module" do
    include_context "List assemblies", module_name, assembly_name, dtk_common
  end

  context "Stage assembly from module" do
    include_context "Stage assembly from module to specific context", module_name, module_location, assembly_name, service_name, context_service_name
  end

  context "Converge service instance" do
    include_context "Converge service instance", service_location, dtk_common, service_name
  end

  context "Delete service instance" do
    include_context "Delete service instance", service_location, service_name, dtk_common
  end

  context "Uninstall service instance" do
    include_context "Uninstall service instance", service_location, service_name
  end

  context "Uninstall module" do
    include_context "Uninstall module", module_name, module_location
  end

  context "Delete initial module on filesystem" do
    include_context "Delete initial module on filesystem", module_location
  end

  context "Delete context instance" do
    include_context "Delete service instance", service_location, context_service_name, dtk_common
  end

  context "Uninstall context instance" do
    include_context "Uninstall service instance", service_location, context_service_name
  end  

  after(:all) do
    puts '', ''
  end
end