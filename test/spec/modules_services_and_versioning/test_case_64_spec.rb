#!/usr/bin/env ruby
#Test Case 64: Export module using full name #{module_name} to users default namespace and then delete it

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'
require './lib/parameters_setting_spec'
require './lib/modules_spec'

namespace = "dtk10"
existing_module_name = "bakir_test"
module_name = "bakir_test1"
module_filesystem_location = "~/component_modules"
$assembly_id = 0

dtk_common = DtkCommon.new('', '')

describe "Test Case 64: Export module using full name #{module_name} to users default namespace and then delete it" do

  before(:all) do
    puts "********************************************************************************************************"
    puts "Test Case 64: Export module using full name #{module_name} to users default namespace and then delete it"
    puts "********************************************************************************************************"
  end

  context "Import module function" do
    include_context "Import remote module", existing_module_name
  end

  context "Get module components list" do
    include_context "Get module components list", dtk_common, existing_module_name
  end

  context "Check if module imported on local filesystem" do
    include_context "Check module imported on local filesystem", module_filesystem_location, existing_module_name
  end

  context "Create new directory called #{module_name} and copy the content of #{existing_module_name} in it" do
    it "creates new directory with existing module content in it" do
      pass = false
      `mkdir #{module_filesystem_location}/#{module_name}`
      `cp -r #{module_filesystem_location}/#{existing_module_name}/* #{module_filesystem_location}/#{module_name}/`
      value = `ls #{module_filesystem_location}/#{module_name}/manifests`
      pass = !value.include?("No such file or directory")
      pass.should eq(true)
    end
  end

  context "Create new module function" do
    include_context "Create module", module_name
  end

  context "Export module to default namespace" do
    include_context "Export module", dtk_common, module_name, namespace
  end

  context "Delete module" do
    include_context "Delete module", dtk_common, module_name
  end

  context "Delete module from local filesystem" do
    include_context "Delete module from local filesystem", module_filesystem_location, module_name
  end

  context "Delete old module" do
    include_context "Delete module", dtk_common, existing_module_name
  end

  context "Delete old module from local filesystem" do
    include_context "Delete module from local filesystem", module_filesystem_location, existing_module_name
  end

  context "Import module function" do
    include_context "Import remote module", "#{namespace}/#{module_name}"
  end

  context "Check if module imported on local filesystem" do
    include_context "Check module imported on local filesystem", module_filesystem_location, module_name
  end

  context "Delete module" do
    include_context "Delete module", dtk_common, module_name
  end

  context "Delete module from local filesystem" do
    include_context "Delete module from local filesystem", module_filesystem_location, module_name
  end

  context "Delete module from remote" do
    include_context "Delete module from remote repo", dtk_common, module_name, namespace
  end

  after(:all) do
    puts "", ""
  end
end