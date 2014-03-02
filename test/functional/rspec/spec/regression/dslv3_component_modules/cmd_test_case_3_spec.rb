#!/usr/bin/env ruby
#Test Case 3: Add new component from dtk.model.yaml file, push-clone-changes to server and list components to see the effect of add

require 'rubygems'
require 'rest_client'
require 'pp'
require 'awesome_print'
require './lib/dtk_common'
require './lib/component_modules_spec'

component_module_name = 'temp'
component_module_namespace = 'dtk17'
component_module_filesystem_location = "~/dtk/component_modules"
file_for_change_location = "./spec/regression/dslv3_component_modules/resources/cmd_test_case_3_dtk.model.yaml"
file_for_change = "dtk.model.yaml"

dtk_common = DtkCommon.new("", "")

describe "(Component Module DSL) Test Case 3: Add new component from dtk.model.yaml file, push-clone-changes to server and list components to see the effect of add" do

  before(:all) do
    puts "*********************************************************************************************************************************************************"
    puts "(Component Module DSL) Test Case 3: Add new component from dtk.model.yaml file, push-clone-changes to server and list components to see the effect of add"
    puts "*********************************************************************************************************************************************************"
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

  context "Add new component in dtk.model.yaml file" do
    include_context "Replace dtk.model.yaml file with new one", component_module_name, file_for_change_location, file_for_change, component_module_filesystem_location, "adds new sink2 component to dtk.model.yaml"
  end

  context "Push clone changes of component module from local copy to server" do
    include_context "Push clone changes to server", component_module_name, file_for_change
  end

  context "Check if sink component exists in component module" do
    include_context "Check if component exists in component module", dtk_common, component_module_name, "sink"
  end

  context "Check if sink2 component exists in component module" do
    include_context "Check if component exists in component module", dtk_common, component_module_name, "sink2"
  end

  context "Check if source component exists in component module" do
    include_context "Check if component exists in component module", dtk_common, component_module_name, "source"
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

