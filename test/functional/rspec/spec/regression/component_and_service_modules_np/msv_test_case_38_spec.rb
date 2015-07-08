#!/usr/bin/env ruby
# Test Case 38: Import to two different namespaces (component module)

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/component_modules_spec'

namespace = "r8"
component_module_name = "apache"
component_module = "r8:apache"
new_component_module = "test:apache"
new_component_module_2 = "test2:apache"
default_filesystem_location = "~/dtk/component_modules"
r8_component_module_filesystem_location = '~/dtk/component_modules/r8'
test_component_module_filesystem_location = '~/dtk/component_modules/test'
test2_component_module_filesystem_location = '~/dtk/component_modules/test2'

dtk_common = DtkCommon.new('', '')

describe "(Modules, Services and Versioning) Test Case 38: Import to two different namespaces (component module)" do
  before(:all) do
    puts "******************************************************************************************************",""
  end

  context "Import component module function" do
    include_context "Import remote component module", namespace + "/" + component_module_name
  end

  context "Get component module components list" do
    include_context "Get component module components list", dtk_common, component_module
  end

  context "Check if component module imported on local filesystem" do
    include_context "Check component module imported on local filesystem", r8_component_module_filesystem_location, component_module_name
  end

  context "Create new directory called #{component_module_name} and copy the content of #{component_module} in it" do
    it "creates new directory with existing component module content in it" do
      puts "Create new directory and copy the content of existing component module", "----------------------------------------------------------------------"
      pass = false
      `mkdir -p #{test_component_module_filesystem_location}/#{component_module_name}`
      `cp -r #{r8_component_module_filesystem_location}/#{component_module_name}/* #{test_component_module_filesystem_location}/#{component_module_name}/`
      value = `ls #{test_component_module_filesystem_location}/#{component_module_name}/manifests`
      pass = !value.include?("No such file or directory")
      puts ""
      pass.should eq(true)
    end
  end

  context "Import new component module function" do
    include_context "Import component module", new_component_module
  end

  context "Get component module components list" do
    include_context "Get component module components list", dtk_common, new_component_module
  end

  context "Check if component module imported on local filesystem" do
    include_context "Check component module imported on local filesystem", test_component_module_filesystem_location, component_module_name
  end

  context "Create new directory called #{component_module_name} and copy the content of #{component_module} in it" do
    it "creates new directory with existing component module content in it" do
      puts "Create new directory and copy the content of existing component module", "----------------------------------------------------------------------"
      pass = false
      `mkdir -p #{test2_component_module_filesystem_location}/#{component_module_name}`
      `cp -r #{r8_component_module_filesystem_location}/#{component_module_name}/* #{test2_component_module_filesystem_location}/#{component_module_name}/`
      value = `ls #{test2_component_module_filesystem_location}/#{component_module_name}/manifests`
      pass = !value.include?("No such file or directory")
      puts ""
      pass.should eq(true)
    end
  end

  context "Import new component module function" do
    include_context "Import component module", new_component_module_2
  end

  context "Get component module components list" do
    include_context "Get component module components list", dtk_common, new_component_module_2
  end

  context "Check if component module imported on local filesystem" do
    include_context "Check component module imported on local filesystem", test2_component_module_filesystem_location, component_module_name
  end  

  context "Delete component module" do
    include_context "Delete component module", dtk_common, component_module
  end

  context "Delete component module from local filesystem" do
    include_context "Delete component module from local filesystem", r8_component_module_filesystem_location, component_module_name
  end

  context "Delete component module" do
    include_context "Delete component module", dtk_common, new_component_module
  end

  context "Delete component module from local filesystem" do
    include_context "Delete component module from local filesystem", test_component_module_filesystem_location, component_module_name
  end

  context "Delete component module" do
    include_context "Delete component module", dtk_common, new_component_module_2
  end

  context "Delete component module from local filesystem" do
    include_context "Delete component module from local filesystem", test2_component_module_filesystem_location, component_module_name
  end

  after(:all) do
    puts "", ""
  end
end