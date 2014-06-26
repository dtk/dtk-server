#!/usr/bin/env ruby
# Test Case 19: Import module from puppet forge, add its components and converge the assembly

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'
require './lib/parameters_setting_spec'
require './lib/modules_spec'

puppet_forge_module_name = "puppetlabs-mysql"
module_name = "mysql"
module_component = "mysql::ruby"
module_filesystem_location = "~/component_modules"

assembly_name = 'msv_test_case_19_instance'
assembly_template = 'bootstrap::node_with_params'
$assembly_id = 0
os = 'rh5.7-64'
os_attribute = 'os_identifier'
memory_size = 't1.micro'
memory_size_attribute = 'memory_size'
node_name = 'node1'

dtk_common = DtkCommon.new(assembly_name, assembly_template)

describe "(Modules, Services and Versioning) Test Case 19: Import module from puppet forge, add its components and converge the assembly" do

  before(:all) do
    puts "******************************************************************************************************************************"
    puts "(Modules, Services and Versioning) Test Case 19: Import module from puppet forge, add its components and converge the assembly"
    puts "******************************************************************************************************************************"
  end

  context "Import module from puppet forge" do
    include_context "Import module from puppet forge", puppet_forge_module_name
  end

  context "Check if module imported on local filesystem" do
    include_context "Check module imported on local filesystem", module_filesystem_location, module_name
  end

  context "Stage assembly function on #{assembly_template} assembly template" do
    include_context "Stage", dtk_common
  end

  context "List assemblies after stage" do
    include_context "List assemblies after stage", dtk_common
  end

  context "Set os attribute function" do
    include_context "Set attribute", dtk_common, os_attribute, os
  end

  context "Set Memory attribute function" do
    include_context "Set attribute", dtk_common, memory_size_attribute, memory_size
  end

  context "Add component to assembly node" do
    include_context "Add specific component to assembly node", dtk_common, node_name, module_component
  end

  context "Converge function" do
    include_context "Converge", dtk_common
  end

  context "Stop assembly function" do
    include_context "Stop assembly", dtk_common
  end 

  context "Delete and destroy assembly function" do
    include_context "Delete assemblies", dtk_common
  end

  context "Delete module" do
    include_context "Delete module", dtk_common, module_name
  end

  context "Delete module from local filesystem" do
    include_context "Delete module from local filesystem", module_filesystem_location, module_name
  end

  after(:all) do
    puts "", ""
  end
end