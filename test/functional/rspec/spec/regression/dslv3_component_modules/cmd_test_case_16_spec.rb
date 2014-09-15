#!/usr/bin/env ruby
# Test Case 16: dtk.model.yaml with hash type attribute that contains two key value pairs and hash type attribute where key contains array as value

require 'rubygems'
require 'rest_client'
require 'pp'
require 'awesome_print'
require './lib/dtk_common'
require './lib/component_modules_spec'

component_module_name = 'temp'
component_module_namespace = 'dtk17'
local_component_module_name = 'dtk17:temp'
component_module_filesystem_location = "~/dtk/component_modules"
component_name = 'source'
attribute_name_1 = 'hash_attr1'
attribute_name_2 = 'hash_attr2'
attribute_value_1 = {"key1"=>["element1", "element2"]}
attribute_value_2 = {"key1"=>"value1", "key2"=>"value2"}
file_for_change_location = "./spec/regression/dslv3_component_modules/resources/cmd_test_case_16_dtk.model.yaml"
file_for_change = "dtk.model.yaml"

dtk_common = DtkCommon.new("", "")

describe "(Component Module DSL) Test Case 16: dtk.model.yaml with hash type attribute that contains two key value pairs and hash type attribute where key contains array as value" do

  before(:all) do
    puts "************************************************************************************************************************************************************************",""
  end

  context "Import component module function" do
    include_context "Import remote component module", component_module_namespace + "/" + component_module_name
  end

  context "Get component module components list" do
    include_context "Get component module components list", dtk_common, local_component_module_name
  end

  context "Check if component module imported on local filesystem" do
    include_context "Check component module imported on local filesystem", component_module_filesystem_location, local_component_module_name
  end

  context "Remove existing component in dtk.model.yaml file" do
    include_context "Replace dtk.model.yaml file with new one", local_component_module_name, file_for_change_location, file_for_change, component_module_filesystem_location, "adds two hash type attributes to dtk.model.yaml"
  end

  context "Push clone changes of component module from local copy to server" do
    include_context "Push clone changes to server", local_component_module_name, file_for_change
  end

  context "Check if expected attribute value for attribute #{attribute_name_1} exist" do
    include_context "Check if expected attribute value exists for given attribute name", dtk_common, local_component_module_name, component_name, attribute_name_1, attribute_value_1
  end

  context "Check if expected attribute value for attribute #{attribute_name_2} exist" do
    include_context "Check if expected attribute value exists for given attribute name", dtk_common, local_component_module_name, component_name, attribute_name_2, attribute_value_2
  end

  context "Delete component module" do
    include_context "Delete component module", dtk_common, local_component_module_name
  end

  context "Delete component module from local filesystem" do
    include_context "Delete component module from local filesystem", component_module_filesystem_location, local_component_module_name
  end

  after(:all) do
    puts "", ""
  end
end

