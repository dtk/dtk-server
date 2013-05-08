#!/usr/bin/env ruby
#Test Case 54: Converge assembly with modified module (added new component and new attribute)

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'
require './lib/parameters_setting_spec'
require './lib/modules_spec'

assembly_name = 'test_case_54_instance'
assembly_template = 'bootstrap::test1'
node_name = 'test1'
component_name1 = 'temp::sink'
component_name2 = 'temp::source'
component_name3 = 'temp::source_test'
module_name = 'temp'
module_filesystem_location = "~/dtk/component_modules"
file_for_change_location = "./lib/spec/dslv2_component_modules/resources/test_case_54_dtk.model.json"
file_for_change = "dtk.model.json"
puppet_file_location = "./lib/spec/dslv2_component_modules/resources/source_test.pp"
puppet_file_name = "source_test.pp"
$assembly_id = 0

dtk_common = DtkCommon.new(assembly_name, assembly_template)

describe "Test Case 54: Converge assembly with modified module (added new component and new attribute)" do

  before(:all) do
    puts "********************************************************************************************"
    puts "Test Case 54: Converge assembly with modified module (added new component and new attribute)"
    puts "********************************************************************************************"
  end

  context "Import module function" do
    include_context "Import remote module", module_name
  end

  context "Upgrade module to DSLv2" do
    it "upgrades #{module_name} module to DSLv2" do
      puts "DSLv2 upgrade:", "---------------------"
      pass = false
      value = `dtk module dsl-upgrade #{module_name}`
      pass = true if (value.include? "Status: OK")
      puts "DSLv2 upgrade of module #{module_name} completed successfully!" if pass == true
      puts "DSLv2 upgrade of module #{module_name} did not complete successfully!" if pass == false
      puts ""
      pass.should eq(true)
    end
  end

  context "Check if module imported on local filesystem" do
    include_context "Check module imported on local filesystem", module_filesystem_location, module_name
  end

  context "Remove existing component attribute in dtk.model.json file" do
    include_context "Replace dtk.model.json file with new one", module_name, file_for_change_location, file_for_change, module_filesystem_location, "adds new source_test component with new param_test attribute dtk.model.json"
  end

  context "Add new puppet file for component #{component_name3}" do
    it "adds new puppet file to manifest" do
      pass = false
      `mv #{puppet_file_location} #{module_filesystem_location}/#{module_name}/manifests`
      value = `ls #{module_filesystem_location}/#{module_name}/manifests/#{puppet_file_name}`
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

