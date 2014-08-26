#!/usr/bin/env ruby
# Test Case 10: Export component module using full name #{component_module_name} to users default namespace and then delete it

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/parameters_setting_spec'
require './lib/component_modules_spec'

existing_component_module_name = "jmeter"
component_module_namespace = "r8"
existing_component_module = "r8::jmeter"
namespace = "dtk17"
component_module_name = "bakir_test1"
local_component_module = "local::bakir_test1"
new_local_component_module = "dtk17::bakir_test1"
component_module_filesystem_location = "~/dtk/component_modules"

dtk_common = DtkCommon.new('', '')

describe "(Modules, Services and Versioning) Test Case 10: Export component module using full name #{component_module_name} to users default namespace and then delete it" do

  before(:all) do
    puts "***************************************************************************************************************************************************************",""
  end

  context "Import component module function" do
    include_context "Import remote component module", component_module_namespace + "/" + existing_component_module_name
  end

  context "Get component module components list" do
    include_context "Get component module components list", dtk_common, existing_component_module
  end

  context "Check if component module imported on local filesystem" do
    include_context "Check component module imported on local filesystem", component_module_filesystem_location, existing_component_module
  end

  context "Create new directory called #{component_module_name} and copy the content of #{existing_component_module} in it" do
    it "creates new directory with existing component module content in it" do
      puts "Create new directory and copy the content of existing component module", "----------------------------------------------------------------------"
      pass = false
      `mkdir #{component_module_filesystem_location}/#{component_module_name}`
      `cp -r #{component_module_filesystem_location}/#{existing_component_module}/* #{component_module_filesystem_location}/#{component_module_name}/`
      value = `ls #{component_module_filesystem_location}/#{component_module_name}/manifests`
      pass = !value.include?("No such file or directory")
      puts ""
      pass.should eq(true)
    end
  end

  context "Import new component module function" do
    include_context "Import component module", component_module_name
  end

  context "Export component module to default namespace" do
    include_context "Export component module", dtk_common, local_component_module, namespace
  end

  context "Delete component module" do
    include_context "Delete component module", dtk_common, local_component_module
  end

  context "Delete component module from local filesystem" do
    include_context "Delete component module from local filesystem", component_module_filesystem_location, local_component_module
  end

  context "Delete old component module" do
    include_context "Delete component module", dtk_common, existing_component_module
  end

  context "Delete old component module from local filesystem" do
    include_context "Delete component module from local filesystem", component_module_filesystem_location, existing_component_module
  end

  context "Import component module function" do
    include_context "Import remote component module", "#{namespace}/#{component_module_name}"
  end

  context "Check if component module imported on local filesystem" do
    include_context "Check component module imported on local filesystem", component_module_filesystem_location, new_local_component_module
  end

  context "Delete component module" do
    include_context "Delete component module", dtk_common, new_local_component_module
  end

  context "Delete component module from local filesystem" do
    include_context "Delete component module from local filesystem", component_module_filesystem_location, new_local_component_module
  end

  context "Delete component module from remote" do
    include_context "Delete component module from remote repo", dtk_common, component_module_name, namespace
  end

  after(:all) do
    puts "", ""
  end
end