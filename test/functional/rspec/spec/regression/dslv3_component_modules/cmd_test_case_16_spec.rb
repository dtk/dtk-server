#!/usr/bin/env ruby
#Test Case 16: dtk.model.yaml with hash type attribute that contains two key value pairs and hash type attribute where key contains array as value

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/modules_spec'

module_name = 'temp'
module_namespace = 'dtk17'
module_filesystem_location = "~/dtk/component_modules"
component_name = 'source'
attribute_name_1 = 'hash_attr1'
attribute_name_2 = 'hash_attr2'
attribute_value_1 = "{\"key1\"=>[\"element1\", \"element2\"]}"
attribute_value_2 = "{\"key1\"=>\"value1\", \"key2\"=>\"value2\"}"
file_for_change_location = "./spec/regression/dslv3_component_modules/resources/cmd_test_case_16_dtk.model.yaml"
file_for_change = "dtk.model.yaml"

dtk_common = DtkCommon.new("", "")

describe "(Component Module DSL) Test Case 16: dtk.model.yaml with hash type attribute that contains two key value pairs and hash type attribute where key contains array as value" do

  before(:all) do
    puts "************************************************************************************************************************************************************************"
    puts "(Component Module DSL) Test Case 16: dtk.model.yaml with hash type attribute that contains two key value pairs and hash type attribute where key contains array as value"
    puts "************************************************************************************************************************************************************************"
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

  context "Remove existing component in dtk.model.yaml file" do
    include_context "Replace dtk.model.yaml file with new one", module_name, file_for_change_location, file_for_change, module_filesystem_location, "adds two hash type attributes to dtk.model.yaml"
  end

  context "Push clone changes of module from local copy to server" do
    include_context "Push clone changes to server", module_name, file_for_change
  end

  context "Check if expected attribute value for attribute #{attribute_name_1} exist" do
    it "gets attribute value and checks that it is hash type and contains key1=value1 and key2=value2" do
      attribute = dtk_common.get_attribute_value_from_module(module_name, component_name, attribute_name_1)
      attribute.should include(attribute_value_1)
    end
  end

  context "Check if expected attribute value for attribute #{attribute_name_2} exist" do
    it "gets attribute value and checks that it is hash type and contains key1 with value [element1, element2]" do
      attribute = dtk_common.get_attribute_value_from_module(module_name, component_name, attribute_name_2)
      attribute.should include(attribute_value_2)
    end
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

