#!/usr/bin/env ruby
#Test Case 30: Import component module from remote, version it and clone it to local filesystem

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/shared_spec'

assembly_name = 'test_case_30_instance'
assembly_template = 'bootstrap::test1'
module_name = 'mysql'
module_version = '0.0.1'
module_filesystem_location = "~/component_modules"
$assembly_id = 0

#Initial empty module components list, will be populated after "Get module components list" context call
$module_components_list = Array.new()
#Initial empty versioned module component list, will be populated after "Get versioned module components list" context call
$versioned_module_components_list = Array.new()

dtk_common = DtkCommon.new(assembly_name, assembly_template)

puts "Test Case 30: Import component module from remote, version it and clone it to local filesystem"

describe "Test Case 30: Import component module from remote, version it and clone it to local filesystem" do

	context "Import module #{module_name} function" do
		include_context "Import remote module", module_name
	end

	context "Get module components list" do
		include_context "Get module components list", dtk_common, module_name
	end

	context "Check if module imported on local filesystem" do
		include_context "Check module imported on local filesystem", module_filesystem_location, module_name
	end	

	context "Create new version of module #{module_name}" do
		include_context "Create new module version", dtk_common, module_name, module_version
	end

	context "Get versioned module components list" do
		include_context "Get versioned module components list", dtk_common, module_name, module_version
	end

	context "Clone versioned module" do
		include_context "Clone versioned module", dtk_common, module_name, module_version
	end	

	context "Check if versioned module cloned on local filesystem" do
		include_context "Check versioned module imported on local filesystem", module_filesystem_location, module_name, module_version
	end

	context "Delete module" do
		include_context "Delete module", dtk_common, module_name
	end

	context "Delete module from local filesystem" do
		include_context "Delete module from local filesystem", module_filesystem_location, module_name
	end

	context "Delete versioned module from local filesystem" do
		include_context "Delete versioned module from local filesystem", module_filesystem_location, module_name, module_version
	end
end