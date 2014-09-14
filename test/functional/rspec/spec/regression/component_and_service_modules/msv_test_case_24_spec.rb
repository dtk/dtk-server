#!/usr/bin/env ruby
# Test Case 24: Import new service module but all component modules for that service module already exist on server and locally

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/service_modules_spec'
require './lib/component_modules_spec'

service_module_name = 'test_apache'
service_module_namespace = 'r8'
local_service_module_name = 'r8:test_apache'
component_module_namespace = 'r8'
component_module_name2 = 'stdlib'
component_module_name3 = 'apache'
local_component_module_name2 = 'r8:stdlib'
local_component_module_name3 = 'r8:apache'
service_module_filesystem_location = '~/dtk/service_modules'
component_module_filesystem_location = '~/dtk/component_modules'
components_list_to_check = ['apache','stdlib']

dtk_common = DtkCommon.new('', '')

describe "(Modules, Services and Versioning) Test Case 24: Import new service module but all component modules for that service module already exist on server and locally" do

  before(:all) do
    puts "****************************************************************************************************************************************************************",""
  end

  context "Import component module function" do
    include_context "Import remote component module", component_module_namespace + "/" + component_module_name3
  end

  context "Check if component module imported on local filesystem" do
    include_context "Check component module imported on local filesystem", component_module_filesystem_location, local_component_module_name3
  end

  context "Check that component module exists" do
    include_context "Check if component module exists", dtk_common, local_component_module_name2
  end

  context "Check that component module exists" do
    include_context "Check if component module exists", dtk_common, local_component_module_name3
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

  context "Delete service module function" do
    include_context "Delete service module", dtk_common, local_service_module_name
  end

  context "Delete service module from local filesystem" do
    include_context "Delete service module from local filesystem", service_module_filesystem_location, local_service_module_name
  end

  context "Delete component module" do
    include_context "Delete component module", dtk_common, local_component_module_name3
  end

  context "Delete component module from local filesystem" do
    include_context "Delete component module from local filesystem", component_module_filesystem_location, local_component_module_name3
  end

  after(:all) do
    puts "", ""
  end
end