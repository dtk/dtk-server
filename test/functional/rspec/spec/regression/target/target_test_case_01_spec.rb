#!/usr/bin/env ruby
require './lib/dtk_cli_spec'
require './lib/dtk_common'

# Target specific properties
service_location = '~/dtk/'
target_location = "/tmp/network"
target_module = 'aws/aws_target'
target_assembly_template = 'target_iam'
target_service_name = 'target_test_case_01'
target_name = 'target_iam'
target_version = 'master'

# Target attributes
default_keypair = 'testing_use1'

# Module specific properties
initial_module_location = "./spec/regression/target/resources/test_module_01_dtk.module.yaml"
module_location = '/tmp/dtk_test_module_01'
module_name = 'test/target_test_module_01'
assembly_name = 'test_assembly'
service_name = 'dtk_test_module_01'

dtk_common = Common.new('', '')

describe "(Target) Test Case 01: Auto-generated vpc data" do
  before(:all) do
    puts '**********************************************', ''
    # Install/clone aws:network module with required dependency modules
    system("rm -rf /tmp/network && mkdir /tmp/network")
    system("dtk module clone -v #{target_version} #{target_module} #{target_location}")
    system("dtk module install --update-deps -d #{target_location} #{target_module}")
  end

  context "List assemblies contained in this module" do
    include_context "List assemblies", target_module, target_assembly_template, dtk_common
  end

  context "Stage target from module" do
    include_context "Stage target from module", target_module, target_location, target_name, target_service_name
  end

  context "Set attribute for default keypair" do
    include_context "Set attribute", service_location, target_service_name, 'network_aws::vpc[vpc1]/default_keypair', default_keypair
  end

  context "Converge service instance" do
    include_context "Converge service instance", service_location, dtk_common, target_service_name
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
    include_context "Stage assembly from module to specific target", module_name, module_location, assembly_name, service_name, target_service_name
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

  context "Delete target instance" do
    include_context "Delete service instance", service_location, target_service_name, dtk_common
  end

  context "Uninstall target instance" do
    include_context "Uninstall service instance", service_location, target_service_name
  end

  after(:all) do
    puts '', ''
  end
end