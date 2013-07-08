#!/usr/bin/env ruby
#Test Case 88: Import new service but some modules already exists for that service on server and locally

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/services_spec'
require './lib/modules_spec'

service_name = 'test_apache'
service_namespace = 'r8'
module_name1 = 'r8_base'
module_name2 = 'stdlib'
module_name3 = 'apache'
service_filesystem_location = '~/dtk/service_modules'
module_filesystem_location = '~/dtk/component_modules'
components_list_to_check = ['apache','r8_base','stdlib']
$assembly_id = 0

dtk_common = DtkCommon.new('', '')

describe "Test Case 88: Import new service but some modules already exists for that service on server and locally" do

  before(:all) do
    puts "*******************************************************************************************************"
    puts "Test Case 88: Import new service but some modules already exists for that service on server and locally"
    puts "*******************************************************************************************************"
    puts ""
  end

  context "Check that module exists" do
    include_context "Check if module exists", dtk_common, module_name1
  end

  context "Check that module exists" do
    include_context "Check if module exists", dtk_common, module_name2
  end

  context "Check if module #{module_name1} imported on local filesystem" do
    include_context "Check module imported on local filesystem", module_filesystem_location, module_name1
  end

  context "Check if module #{module_name2} imported on local filesystem" do
    include_context "Check module imported on local filesystem", module_filesystem_location, module_name2
  end

  context "Import service function" do
    include_context "Import remote service", dtk_common, service_namespace + "/" + service_name
  end

  context "List all services" do
    include_context "List all services", dtk_common, service_name
  end

  context "Check if service imported on local filesystem" do
    include_context "Check service imported on local filesystem", service_filesystem_location, service_name
  end

  context "Check component modules exist in service" do
    include_context "Check component modules in service", dtk_common, service_name, components_list_to_check
  end

  context "Check that module #{module_name3} exists (automatically imported with service)" do
    include_context "Check if module exists", dtk_common, module_name3
  end

  context "Check if module #{module_name3} imported on local filesystem" do
    include_context "Check module imported on local filesystem", module_filesystem_location, module_name3
  end

  context "Delete service function" do
    include_context "Delete service", dtk_common, service_name
  end

  context "Delete service from local filesystem" do
    include_context "Delete service from local filesystem", service_filesystem_location, service_name
  end

  context "Delete module" do
    include_context "Delete module", dtk_common, module_name3
  end

  context "Delete module from local filesystem" do
    include_context "Delete module from local filesystem", module_filesystem_location, module_name3
  end

  after(:all) do
    puts "", ""
  end
end