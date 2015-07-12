#!/usr/bin/env ruby
# Test Case 15: dtk.model.yaml with hash type attribute that contains key without value

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
component_name = 'source'
attribute_name = 'hash_attr'
file_for_change_location = "./spec/regression/dslv3_component_modules_np/resources/cmd_test_case_15_dtk.model.yaml"
file_for_change = "dtk.model.yaml"
attribute_value_hash = {"key1"=>nil}

dtk_common = Common.new("", "")

describe "(Component Module DSL) Test Case 15: dtk.model.yaml with hash type attribute that contains key without value" do

  before(:all) do
    puts "************************************************************************************************************",""
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
    include_context "Replace dtk.model.yaml file with new one", component_module_name, file_for_change_location, file_for_change, component_module_filesystem_location, "adds hash type attribute that contains key without value to dtk.model.yaml"
  end

  context "Push clone changes of component module from local copy to server" do
    include_context "Push clone changes to server", local_component_module_name, file_for_change
  end

  context "Check if expected attribute value for attribute exist" do
    include_context "Check if expected attribute value exists for given attribute name", dtk_common, local_component_module_name, component_name, attribute_name, attribute_value_hash
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

