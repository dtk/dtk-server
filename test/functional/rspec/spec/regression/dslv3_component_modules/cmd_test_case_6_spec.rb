#!/usr/bin/env ruby
#Test Case 6: Add new component attribute in dtk.model.yaml file, push-clone-changes to server and check if component attribute present

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'
require './lib/parameters_setting_spec'
require './lib/modules_spec'

assembly_name = 'cmd_test_case_6_instance'
assembly_template = 'bootstrap::test1'
node_name = 'test1'
component_name1 = 'temp::source'
component_name2 = 'temp::sink'
module_name = 'temp'
module_namespace = 'dtk17'
module_filesystem_location = "~/dtk/component_modules"
file_for_change_location = "./spec/regression/dslv3_component_modules/resources/cmd_test_case_6_dtk.model.yaml"
file_for_change = "dtk.model.yaml"
$assembly_id = 0

dtk_common = DtkCommon.new(assembly_name, assembly_template)

describe "(Component Module DSL) Test Case 6: Add new component attribute in dtk.model.yaml file, push-clone-changes to server and check if component attribute present" do

  before(:all) do
    puts "*************************************************************************************************************************************************************"
    puts "(Component Module DSL) Test Case 6: Add new component attribute in dtk.model.yaml file, push-clone-changes to server and check if component attribute present"
    puts "*************************************************************************************************************************************************************"
    puts ""
  end

  context "Import module function" do
    include_context "Import remote module", module_namespace + "/" + module_name
  end

  context "Get module components list" do
    include_context "Get module components list", dtk_common, module_name
  end

  context "Check if module imported on local filesystem" do
    include_context "Check module imported on local filesystem", module_filesystem_location, module_name
  end

  context "Add new component attribute in dtk.model.yaml file" do
    include_context "Replace dtk.model.yaml file with new one", module_name, file_for_change_location, file_for_change, module_filesystem_location, "adds param1 attribute to source component in dtk.model.yaml"
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

  context "Check param1 attribute exist on source component" do
    include_context "Check attribute present in component", dtk_common, node_name, component_name1, 'param1', ''
  end

  context "Check param2 attribute exist on source component" do
    include_context "Check attribute present in component", dtk_common, node_name, component_name1, 'param2', ''
  end

  context "Check param1 attribute exist on sink component" do
    include_context "Check attribute present in component", dtk_common, node_name, component_name2, 'param1', ''
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

