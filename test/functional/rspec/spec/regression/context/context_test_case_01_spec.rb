#!/usr/bin/env ruby
require './lib/dtk_cli_spec'
require './lib/dtk_common'

# Context specific properties
service_location = '~/dtk/'
context_location = "/tmp/network"
context_module = 'aws/aws_target'
context_assembly_template = 'target_iam'
context_service_name = 'context_test_case_01'
context_name = 'target_iam'
context_version = 'master'

# Context attributes
default_keypair = 'testing_use1'

# Module specific properties
initial_module_location = "./spec/regression/context/resources/test_module_01_dtk.module.yaml"
module_location = '/tmp/dtk_test_module_01'
module_name = 'test/context_test_module_01'
assembly_name = 'test_assembly'
service_name = 'dtk_test_module_01'

dtk_common = Common.new('', '')

describe "(Context) Test Case 01: Auto-generated vpc data" do
  before(:all) do
    puts '**********************************************', ''
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
    include_context "Set attribute", service_location, context_service_name, 'network_aws::vpc[vpc1]/default_keypair', default_keypair
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