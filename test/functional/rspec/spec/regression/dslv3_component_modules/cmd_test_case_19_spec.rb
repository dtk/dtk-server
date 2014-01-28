#!/usr/bin/env ruby
#Test Case 19: NEG - dtk.model.yaml with invalid boolean type attribute value

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
file_for_change_location = "./spec/regression/dslv3_component_modules/resources/cmd_test_case_19_dtk.model.yaml"
file_for_change = "dtk.model.yaml"
false_boolean_value = "falsee"

dtk_common = DtkCommon.new("", "")

describe "(Component Module DSL) Test Case 19: NEG - dtk.model.yaml with invalid boolean type attribute value" do

  before(:all) do
    puts "***************************************************************************************************"
    puts "(Component Module DSL) Test Case 19: NEG - dtk.model.yaml with invalid boolean type attribute value"
    puts "***************************************************************************************************"
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
    include_context "Replace dtk.model.yaml file with new one", module_name, file_for_change_location, file_for_change, module_filesystem_location, "adds invalid boolean type attribute value to dtk.model.yaml"
  end

  context "Push clone changes of module from local copy to server" do
    it "pushes module changes from local filesystem to server but fails because of incorrect value for boolean type attribute: #{false_boolean_value}" do
      fail = false
      value = `dtk module #{module_name} push`
      puts value
      fail = value.include?("[ERROR] Attribute (boolean_attr) has default value (\"#{false_boolean_value}\") that does not match its type (boolean)")
      fail.should eq(true)  
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

