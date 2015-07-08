#!/usr/bin/env ruby
# Test Case 4: Get list of all assemblies for particular service module

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/service_modules_spec'

service_name = 'msv_test_case_4_instance'
assembly_name = 'bootstrap::test1'
new_assembly_name = 'msv_test_case_4_temp'
service_module_filesystem_location = '~/dtk/service_modules/local'
service_module_name = 'new_service'
local_service_module_name = 'local:new_service'
local_namespace = "local"

dtk_common = DtkCommon.new(service_name, assembly_name)

describe "(Modules, Services and Versioning) Test Case 4: Get list of all assemblies for particular service module" do
  before(:all) do
    puts "********************************************************************************************************",""
  end

  context "Stage service on #{assembly_name} assembly" do
    include_context "Stage", dtk_common
  end

  context "List services after stage" do
    include_context "List services after stage", dtk_common
  end

  context "Create assembly from existing service" do
    include_context "Create assembly from service", dtk_common, service_module_name, new_assembly_name, local_namespace
  end

  context "Check if #{new_assembly_name} assembly belongs to #{local_service_module_name} service module" do
    include_context "Check if assembly belongs to the service module", dtk_common, local_service_module_name, new_assembly_name
  end

  context "Delete assembly" do
    include_context "Delete assembly", dtk_common, service_module_name + "/" + new_assembly_name, local_namespace
  end

  context "Delete and destroy service function" do
    include_context "Delete services", dtk_common
  end

  context "List services after delete" do
    include_context "List services after delete", dtk_common
  end

  context "Delete service module function" do
    include_context "Delete service module", dtk_common, local_service_module_name
  end

  context "Delete service module from local filesystem" do
  include_context "Delete service module from local filesystem", service_module_filesystem_location, service_module_name
  end

  after(:all) do
    puts "", ""
  end
end
