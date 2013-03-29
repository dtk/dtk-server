#!/usr/bin/env ruby
#Test Case 64: Create module in new namespace #{namespace} and try to import it using full name #{namespace}/#{module_name}

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'
require './lib/parameters_setting_spec'
require './lib/modules_spec'

namespace = "test"
existing_module_name = "bakir_test"
module_name = "bakir_test1"
module_filesystem_location = "~/component_modules"
$assembly_id = 0
#Initial empty module components list, will be populated after "Get module components list" context call
$module_components_list = Array.new()

dtk_common = DtkCommon.new('', '')

puts "Test Case 64: Create module in new namespace #{namespace} and try to import it using full name #{namespace}/#{module_name}"

describe "Test Case 64: Create module in new namespace #{namespace} and try to import it using full name #{namespace}/#{module_name}" do

  context "Import module #{existing_module_name} function" do
    include_context "Import remote module", existing_module_name
  end

  context "Get module components list" do
    include_context "Get module components list", dtk_common, existing_module_name
  end

  context "Check if module #{existing_module_name} imported on local filesystem" do
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

  context "Create new module #{module_name}" do
    include_context "Create module", module_name
  end

  context "Export module #{module_name} to new namespace #{namespace}" do
    include_context "Export module", module_name, namespace
  end

  context "Delete module #{module_name}" do
    include_context "Delete module", dtk_common, module_name
  end

  context "Delete module #{module_name} from local filesystem" do
    include_context "Delete module from local filesystem", module_filesystem_location, module_name
  end

  context "Delete old module #{existing_module_name}" do
    include_context "Delete module", dtk_common, existing_module_name
  end

  context "Delete old module #{existing_module_name} from local filesystem" do
    include_context "Delete module from local filesystem", module_filesystem_location, existing_module_name
  end

  context "Import module #{module_name} function" do
    include_context "Import remote module", "#{namespace}/#{module_name}"
  end

  context "Check if module #{module_name} imported on local filesystem" do
    include_context "Check module imported on local filesystem", module_filesystem_location, module_name
  end

  context "Delete module #{module_name}" do
    include_context "Delete module", dtk_common, module_name
  end

  context "Delete module #{module_name} from local filesystem" do
    include_context "Delete module from local filesystem", module_filesystem_location, module_name
  end
end