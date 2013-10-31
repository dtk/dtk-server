#!/usr/bin/env ruby
#Test Case 7: Converge assembly with modified module (added new component and new attribute)

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'
require './lib/parameters_setting_spec'
require './lib/modules_spec'

assembly_name = 'cmd_test_case_7_instance'
assembly_template = 'bootstrap::node_with_params'
os_attribute = 'os_identifier'
memory_size_attribute = 'memory_size'
os = 'precise'
memory_size = 't1.micro'
node_name = 'test1'
component_name1 = 'temp::sink'
component_name2 = 'temp::source'
component_name3 = 'temp::source_test'
module_name = 'temp'
module_namespace = 'dtk17'
module_filesystem_location = "~/dtk/component_modules"
file_for_change_location = "./spec/dslv2_component_modules/resources/cmd_test_case_7_dtk.model.json"
file_for_change = "dtk.model.json"

puppet_file_location = "./spec/dslv2_component_modules/resources/source_test.pp"
puppet_file_name = "source_test.pp"

puppet_file_location2 = "./spec/dslv2_component_modules/resources/sink.pp"
puppet_file_name2 = "sink.pp"

$assembly_id = 0

dtk_common = DtkCommon.new(assembly_name, assembly_template)

describe "(Component Module DSL) Test Case 7: Converge assembly with modified module (added new component and new attribute)" do

  before(:all) do
    puts "******************************************************************************************************************"
    puts "(Component Module DSL) Test Case 7: Converge assembly with modified module (added new component and new attribute)"
    puts "******************************************************************************************************************"
    puts ""
  end

  context "Import module function" do
    include_context "Import remote module", module_namespace + "/" + module_name
  end

  context "Check if module imported on local filesystem" do
    include_context "Check module imported on local filesystem", module_filesystem_location, module_name
  end

  context "Add new component and new attribute in dtk.model.json file" do
    include_context "Replace dtk.model.json file with new one", module_name, file_for_change_location, file_for_change, module_filesystem_location, "adds new source_test component with new param_test attribute dtk.model.json"
  end

  context "Add new puppet file for component #{component_name3}" do
    it "adds new puppet file to manifest" do
      pass = false
      `cp #{puppet_file_location} #{module_filesystem_location}/#{module_name}/manifests`
      value = `ls #{module_filesystem_location}/#{module_name}/manifests/#{puppet_file_name}`
      pass = !value.include?("No such file or directory")
      pass.should eq(true)
    end
  end

  context "Replace existing puppet file for component #{component_name1}" do
    it "replaces existing puppet file in manifest" do
      pass = false
      `cp #{puppet_file_location2} #{module_filesystem_location}/#{module_name}/manifests`
      value = `ls #{module_filesystem_location}/#{module_name}/manifests/#{puppet_file_name2}`
      pass = !value.include?("No such file or directory")
      pass.should eq(true)
    end
  end

  context "Push clone changes of module from local copy to server" do
    include_context "Push clone changes to server", module_name, file_for_change
  end

  context "Get module components list" do
    include_context "Get module components list", dtk_common, module_name
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

  context "Set memory size attribute function" do
    include_context "Set attribute", dtk_common, memory_size_attribute, memory_size
  end

  context "Add components to assembly node" do
    include_context "Add component to assembly node", dtk_common, node_name
  end

  context "Check param1 attribute exists on #{component_name1} component" do
    include_context "Check attribute present in component", dtk_common, node_name, component_name1, 'param1', ''
  end

  context "Check param2 attribute exists on #{component_name2} component" do
    include_context "Check attribute present in component", dtk_common, node_name, component_name2, 'param2', ''
  end

  context "Check param2 attribute exists on #{component_name3} component" do
    include_context "Check attribute present in component", dtk_common, node_name, component_name3, 'param2', ''
  end

  context "Check param_test attribute exists on #{component_name3} component" do
    include_context "Check attribute present in component", dtk_common, node_name, component_name3, 'param_test', ''
  end

  context "Converge function" do
    include_context "Converge", dtk_common
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

