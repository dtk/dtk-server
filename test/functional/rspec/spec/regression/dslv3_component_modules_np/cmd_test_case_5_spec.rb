#!/usr/bin/env ruby
# Test Case 5: Rename existing component attribute in dtk.model.yaml file, push-clone-changes to server and check if component attribute present

require 'rubygems'
require 'rest_client'
require 'pp'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/parameters_setting_spec'
require './lib/component_modules_spec'

service_name = 'cmd_test_case_5_instance'
assembly_name = 'bootstrap::test1'
node_name = 'test1'
component_name = 'temp::source'
component_module_name = 'temp'
component_module_namespace = 'dtk17'
local_component_module_name = 'dtk17:temp'
component_module_filesystem_location = "~/dtk/component_modules/dtk17"
file_for_change_location = "./spec/regression/dslv3_component_modules_np/resources/cmd_test_case_5_dtk.model.yaml"
file_for_change = "dtk.model.yaml"

dtk_common = DtkCommon.new(service_name, assembly_name)

describe "(Component Module DSL) Test Case 5: Rename existing component attribute in dtk.model.yaml file, push-clone-changes to server and check if component attribute present" do
  before(:all) do
    puts "*********************************************************************************************************************************************************************",""
  end

  context "Import component module function" do
    include_context "Import remote component module", component_module_namespace + "/" + component_module_name
  end

  context "Get component module components list" do
    include_context "Get component module components list", dtk_common, local_component_module_name
  end

  context "Check if component module imported on local filesystem" do
    include_context "Check component module imported on local filesystem", component_module_filesystem_location, component_module_name
  end

  context "Rename existing component attribute in dtk.model.yaml file" do
    include_context "Replace dtk.model.yaml file with new one", component_module_name, file_for_change_location, file_for_change, component_module_filesystem_location, "renames param2 attribute from source component to test_attribute in dtk.model.yaml"
  end

  context "Push clone changes of component module from local copy to server" do
    include_context "Push clone changes to server", local_component_module_name, file_for_change
  end

  context "Stage service function on #{assembly_name} assembly" do
    include_context "Stage", dtk_common
  end

  context "List services after stage" do
    include_context "List services after stage", dtk_common
  end

  context "Add components to service node" do
    include_context "Add component to service node", dtk_common, node_name, component_module_name, component_module_namespace
  end

  context "Check param2 attribute does not exist on source component" do
    include_context "Check attribute not present in component", dtk_common, node_name, component_name, 'param2', ''
  end

  context "Check test_attribute attribute exist on source component" do
    include_context "Check attribute present in component", dtk_common, node_name, component_name, 'test_attribute', ''
  end

  context "Delete and destroy service function" do
    include_context "Delete services", dtk_common
  end

  context "Delete component module" do
    include_context "Delete component module", dtk_common, local_component_module_name
  end

  context "Delete component module from local filesystem" do
    include_context "Delete component module from local filesystem", component_module_filesystem_location, component_module_name
  end

  after(:all) do
    puts "", ""
  end
end

