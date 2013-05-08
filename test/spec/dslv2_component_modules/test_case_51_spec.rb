#!/usr/bin/env ruby
#Test Case 51: Remove existing component attribute from dtk.model.json file, push-clone-changes to server and check if component attribute present

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'
require './lib/parameters_setting_spec'
require './lib/modules_spec'

assembly_name = 'test_case_51_instance'
assembly_template = 'bootstrap::test1'
node_name = 'test1'
component_name = 'temp::source'
module_name = 'temp'
module_filesystem_location = "~/dtk/component_modules"
file_for_change_location = "./spec/dslv2_component_modules/resources/test_case_51_dtk.model.json"
file_for_change = "dtk.model.json"
$assembly_id = 0

dtk_common = DtkCommon.new(assembly_name, assembly_template)

describe "Test Case 51: Remove existing component attribute from dtk.model.json file, push-clone-changes to server and check if component attribute present" do

  before(:all) do
    puts "*************************************************************************************************************************************************"
    puts "Test Case 51: Remove existing component attribute from dtk.model.json file, push-clone-changes to server and check if component attribute present"
    puts "*************************************************************************************************************************************************"
  end

  context "Import module function" do
    include_context "Import remote module", module_name
  end

  context "Upgrade module to DSLv2" do
    it "upgrades #{module_name} module to DSLv2" do
      puts "DSLv2 upgrade:", "---------------------"
      pass = false
      value = `dtk module #{module_name} dsl-upgrade`
      pass = true if (value.include? "Status: OK")
      puts "DSLv2 upgrade of module #{module_name} completed successfully!" if pass == true
      puts "DSLv2 upgrade of module #{module_name} did not complete successfully!" if pass == false
      puts ""
      pass.should eq(true)
    end
  end

  context "Get module components list" do
    include_context "Get module components list", dtk_common, module_name
  end

  context "Check if module imported on local filesystem" do
    include_context "Check module imported on local filesystem", module_filesystem_location, module_name
  end

  context "Remove existing component attribute in dtk.model.json file" do
    include_context "Replace dtk.model.json file with new one", module_name, file_for_change_location, file_for_change, module_filesystem_location, "removes param2 attribute from source component in dtk.model.json"
  end

  context "Push clone changes of module from local copy to server" do
    include_context "Push clone changes to server", module_name, file_for_change
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

  context "Check param2 attribute does not exist on source component" do
    include_context "Check attribute not present in component", dtk_common, node_name, component_name, 'param2', ''
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

