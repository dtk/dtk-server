#!/usr/bin/env ruby
# Test Case 53: Check that changes on base component module can be pulled on instance component

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/component_modules_spec'
require './lib/service_modules_spec'

service_name = 'msv_test_case_53_instance'
assembly_name = 'test_apache::test_apache'
component_module_name = "apache"
service_module_name = "test_apache"
namespace = "r8"
component_module_filesystem_location = '~/dtk/component_modules/r8'
service_module_filesystem_location = '~/dtk/service_modules/r8'
instance_component_filesystem_location = "~/dtk/assemblies/#{service_name}/component_modules/r8:apache"
file_name = "mytest" + Random.rand(100).to_s
command_to_execute = "date > #{file_name}"
command_to_verify = "ls"
dtk_common = Common.new(service_name, assembly_name)

describe "(Modules, Services and Versioning) Test Case 53: Check that changes on base component module can be pulled on instance component" do

  before(:all) do
    puts "********************************************************************************************************************************",""
  end

  context "Import service module function" do
    include_context "Import remote service module", namespace + "/" + service_module_name
  end

  context "List all service modules" do
    include_context "List all service modules", dtk_common, namespace + ":" + service_module_name
  end

  context "Get component module components list" do
    include_context "Get component module components list", dtk_common, namespace + ":" + component_module_name
  end

  context "Check if component module imported on local filesystem" do
    include_context "Check component module imported on local filesystem", component_module_filesystem_location, component_module_name
  end

  context "Check if service module imported on local filesystem" do
    include_context "Check service module imported on local filesystem", service_module_filesystem_location, service_module_name
  end

  context "Stage service function on #{assembly_name} assembly" do
    include_context "Stage", dtk_common
  end

  context "List services after stage" do    
    include_context "List services after stage", dtk_common
  end

  context "Pull base component module" do
    include_context "Pull base component module", dtk_common, component_module_name
  end

  context "Make change on instance component" do
    include_context "Make change on instance component", instance_component_filesystem_location, command_to_execute, command_to_verify, file_name
  end

  context "Verify update/update saved flags for instance component module" do
    include_context "Verify update/update saved flags", dtk_common, component_module_name, false, false
  end

  context "Push component module updates" do
    include_context "Push component module updates", dtk_common, component_module_name
  end

  context "Verify update/update saved flags for instance component module" do
    include_context "Verify update/update saved flags", dtk_common, component_module_name, true, true
  end

  context "Verify change on base component module" do
    include_context "Verify change on base component module", component_module_filesystem_location, component_module_name, command_to_verify, file_name
  end

  context "Delete and destroy service function" do
    include_context "Delete services", dtk_common
  end

  context "List services after delete" do
    include_context "List services after delete", dtk_common
  end

  context "Delete service module function" do
    include_context "Delete service module", dtk_common, namespace + ":" + service_module_name
  end

  context "Delete service module from local filesystem" do
    include_context "Delete service module from local filesystem", service_module_filesystem_location, service_module_name
  end

  context "Delete component module" do
    include_context "Delete component module", dtk_common, namespace + ":" + component_module_name
  end

  context "Delete component module from local filesystem" do
    include_context "Delete component module from local filesystem", component_module_filesystem_location, component_module_name
  end

  after(:all) do
    puts "", ""
  end
end