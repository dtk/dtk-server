#!/usr/bin/env ruby
# Test Case 40: Install service module with dependency to one component and that component has dependency to another component

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/service_modules_spec'
require './lib/component_modules_spec'

namespace = "r8"
component_module_name_1 = "tomcat"
component_module_1 = "r8:tomcat"
component_module_name_2 = "concat"
component_module_2 = "r8:concat"
service_module_name = "test_service_module_3"
service_module = "r8:test_service_module_3"
r8_service_module_filesystem_location = '~/dtk/service_modules/r8'
r8_component_module_filesystem_location = '~/dtk/component_modules/r8'
file_for_change_location = "./spec/regression/component_and_service_modules/resources/msv_test_case_40_module_refs.yaml"
file_for_add = "module_refs.yaml"
file_for_remove = "module_refs.yaml"

dtk_common = DtkCommon.new('', '')

describe "(Modules, Services and Versioning) Test Case 40: Install service module with dependency to one component and that component has dependency to another component" do

  before(:all) do
    puts "***************************************************************************************************************************************************************",""
  end

  context "Import component module function" do
    include_context "Import remote component module", namespace + "/" + component_module_name_1
  end

  context "Get component module components list" do
    include_context "Get component module components list", dtk_common, component_module_1
  end

  context "Add module_refs.yaml file" do
    include_context "Add module_refs.yaml file", component_module_name_1, file_for_change_location, file_for_add, r8_component_module_filesystem_location
  end

  context "Push clone changes of component module from local copy to server" do
    include_context "Push clone changes to server", component_module_1, file_for_add
  end

  context "Push to remote changes for component module" do
  	include_context "Push to remote changes for component module", dtk_common, component_module_1
  end

  context "Delete component module" do
    include_context "Delete component module", dtk_common, component_module_1
  end

  context "Delete component module from local filesystem" do
    include_context "Delete component module from local filesystem", r8_component_module_filesystem_location, component_module_name_1
  end

  context "Install service module function" do
    include_context "Import remote service module", namespace + "/" + service_module_name
  end

  context "List all service modules" do
    include_context "List all service modules", dtk_common, service_module
  end

  context "Get component module components list" do
    include_context "Get component module components list", dtk_common, component_module_1
  end

  context "Get component module components list" do
    include_context "Get component module components list", dtk_common, component_module_2
  end

  # Cleanup
  context "Remove module_refs.yaml file" do
    include_context "Remove module_refs.yaml file", component_module_name_1, file_for_remove, r8_component_module_filesystem_location
  end

  context "Push to remote changes for component module" do
  	include_context "Push to remote changes for component module", dtk_common, component_module_1
  end

  context "Delete service module" do
    include_context "Delete service module", dtk_common, service_module
  end

  context "Delete service module from local filesystem" do
    include_context "Delete service module from local filesystem", r8_service_module_filesystem_location, service_module_name
  end

  context "Delete component module" do
    include_context "Delete component module", dtk_common, component_module_1
  end

  context "Delete component module from local filesystem" do
    include_context "Delete component module from local filesystem", r8_component_module_filesystem_location, component_module_name_1
  end

  context "Delete component module" do
    include_context "Delete component module", dtk_common, component_module_2
  end

  context "Delete component module from local filesystem" do
    include_context "Delete component module from local filesystem", r8_component_module_filesystem_location, component_module_name_2
  end

  after(:all) do
    puts "", ""
  end
end