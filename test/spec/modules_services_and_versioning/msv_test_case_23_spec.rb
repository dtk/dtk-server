#!/usr/bin/env ruby
#Test Case 23: Import new service and import all modules for that service automatically

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/services_spec'
require './lib/modules_spec'

service_name = 'bakir_test_apache'
service_namespace = 'r8'
module_name = 'apache'
service_filesystem_location = '~/dtk/service_modules'
module_filesystem_location = '~/dtk/component_modules'
components_list_to_check = ['apache']
$assembly_id = 0

dtk_common = DtkCommon.new('', '')

describe "(Modules, Services and Versioning) Test Case 23: Import new service and import all modules for that service automatically" do

  before(:all) do
    puts "*************************************************************************************************************************"
    puts "(Modules, Services and Versioning) Test Case 23: Import new service and import all modules for that service automatically"
    puts "*************************************************************************************************************************"
    puts ""
  end

  context "Check that module does not exist" do
    include_context "NEG - Check if module exists", dtk_common, module_name
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

  context "Check that module exists" do
    include_context "Check if module exists", dtk_common, module_name
  end

  context "Delete service function" do
    include_context "Delete service", dtk_common, service_name
  end

  context "Delete service from local filesystem" do
    include_context "Delete service from local filesystem", service_filesystem_location, service_name
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