#!/usr/bin/env ruby
# Test Case 17: NEG - dtk.model.yaml with invalid port type attribute value

require 'rubygems'
require 'rest_client'
require 'pp'
require 'awesome_print'
require './lib/dtk_common'
require './lib/component_modules_spec'

component_module_name = 'temp'
component_module_namespace = 'dtk17'
component_module_filesystem_location = "~/dtk/component_modules"
file_for_change_location = "./spec/regression/dslv3_component_modules/resources/cmd_test_case_17_dtk.model.yaml"
file_for_change = "dtk.model.yaml"
port_attr_value = "8080a"
fail_message = "incorrect value for port type attribute: #{port_attr_value}"
expected_error_message = "[ERROR] Attribute (port_attr) has default value (\"#{port_attr_value}\") that does not match its type (port)"

dtk_common = DtkCommon.new("", "")

describe "(Component Module DSL) Test Case 17: NEG - dtk.model.yaml with invalid port type attribute value" do

  before(:all) do
    puts "************************************************************************************************"
    puts "(Component Module DSL) Test Case 17: NEG - dtk.model.yaml with invalid port type attribute value"
    puts "************************************************************************************************"
    puts ""
  end

  context "Import component module function" do
    include_context "Import remote component module", component_module_namespace + "/" + component_module_name
  end

  context "Get component module components list" do
    include_context "Get component module components list", dtk_common, component_module_name
  end

  context "Check if component module imported on local filesystem" do
    include_context "Check component module imported on local filesystem", component_module_filesystem_location, component_module_name
  end

  context "Remove existing component in dtk.model.yaml file" do
    include_context "Replace dtk.model.yaml file with new one", component_module_name, file_for_change_location, file_for_change, component_module_filesystem_location, "adds incorrect port type attribute value to dtk.model.yaml"
  end

  context "Push clone changes of component module from local copy to server" do
    include_context "NEG - Push clone changes to server", component_module_name, fail_message, expected_error_message
  end

  context "Delete component module" do
    include_context "Delete component module", dtk_common, component_module_name
  end

  context "Delete component module from local filesystem" do
    include_context "Delete component module from local filesystem", component_module_filesystem_location, component_module_name
  end

  after(:all) do
    puts "", ""
  end
end

