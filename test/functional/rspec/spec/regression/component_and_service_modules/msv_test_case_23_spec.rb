#!/usr/bin/env ruby
# Test Case 23: Import new service module and import all component modules for that service module automatically

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/service_modules_spec'
require './lib/component_modules_spec'

service_module_name = 'bakir_test_apache'
service_module_namespace = 'r8'
local_service_module_name = "r8::bakir_test_apache"
component_module_name = 'r8::apache'
service_module_filesystem_location = '~/dtk/service_modules'
component_module_filesystem_location = '~/dtk/component_modules'
components_list_to_check = ['apache']

dtk_common = DtkCommon.new('', '')

describe "(Modules, Services and Versioning) Test Case 23: Import new service module and import all component modules for that service module automatically" do

  before(:all) do
    puts "*************************************************************************************************************************************************",""
  end

  context "Check that component module does not exist" do
    include_context "NEG - Check if component module exists", dtk_common, component_module_name
  end

  context "Import service module function" do
    include_context "Import remote service module", service_module_namespace + "/" + service_module_name
  end

  context "List all service modules" do
    include_context "List all service modules", dtk_common, local_service_module_name
  end

  context "Check if service module imported on local filesystem" do
    include_context "Check service module imported on local filesystem", service_module_filesystem_location, local_service_module_name
  end

  context "Check component modules exist in service module" do
    include_context "Check component modules in service module", dtk_common, local_service_module_name, components_list_to_check
  end

  context "Check that component module exists" do
    include_context "Check if component module exists", dtk_common, component_module_name
  end

  context "Delete service module function" do
    include_context "Delete service module", dtk_common, local_service_module_name
  end

  context "Delete service module from local filesystem" do
    include_context "Delete service module from local filesystem", service_module_filesystem_location, local_service_module_name
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