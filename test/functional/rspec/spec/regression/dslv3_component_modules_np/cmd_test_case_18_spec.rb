#!/usr/bin/env ruby
# Test Case 18: NEG - dtk.model.yaml with invalid integer type attribute value

require 'rubygems'
require 'rest_client'
require 'pp'
require 'awesome_print'
require './lib/dtk_common'
require './lib/component_modules_spec'

component_module_name = 'temp'
component_module_namespace = 'dtk17'
local_component_module_name = 'dtk17:temp'
component_module_filesystem_location = "~/dtk/component_modules/dtk17"
file_for_change_location = "./spec/regression/dslv3_component_modules_np/resources/cmd_test_case_18_dtk.model.yaml"
file_for_change = "dtk.model.yaml"
false_integer_value = "some_value"
fail_message = "incorrect value for integer type attribute: #{false_integer_value}"
expected_error_message = "[ERROR] Attribute (integer_attr) has default value (\"#{false_integer_value}\") that does not match its type (integer)"

dtk_common = Common.new("", "")

describe "(Component Module DSL) Test Case 18: NEG - dtk.model.yaml with invalid integer type attribute value" do

  before(:all) do
    puts "***************************************************************************************************",""
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

  context "Remove existing component in dtk.model.yaml file" do
    include_context "Replace dtk.model.yaml file with new one", component_module_name, file_for_change_location, file_for_change, component_module_filesystem_location, "adds invalid integer type attribute value to dtk.model.yaml"
  end

  context "Push clone changes of component module from local copy to server" do
    include_context "NEG - Push clone changes to server", local_component_module_name, fail_message, expected_error_message
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

