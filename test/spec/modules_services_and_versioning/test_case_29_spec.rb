#!/usr/bin/env ruby
#Test Case 29: Import component module from remote, version it and use this version-ed component in assembly

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './test/lib/dtk_common'
require './test/lib/shared_spec'

assembly_name = 'test_case_29_instance'
assembly_template = 'bootstrap::node_with_params'
os = 'natty'
node_name = 'node1'
module_name = "mysql"
module_version = "0.0.1"
module_filesystem_location = "~/component_modules"
$assembly_id = 0

#Initial empty module components list, will be populated after "Get module components list" context call
$module_components_list = Array.new()
#Initial empty versioned module component list, will be populated after "Get versioned module components list" context call
$versioned_module_components_list = Array.new()

dtk_common = DtkCommon.new(assembly_name, assembly_template)

describe "Test Case 29: Import component module from remote, version it and use this version-ed component in assembly" do

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

	context "Stage assembly function" do
		include_context "Stage", dtk_common
	end

	context "List assemblies after stage" do		
		include_context "List assemblies after stage", dtk_common
	end

	context "Set OS attribute function" do
		include_context "Set attribute", dtk_common, 'os_identifier', os
	end

	context "Add versioned components to assembly node" do
		$versioned_module_components_list.each do |component_id|
			include_context "Add component to assembly node", dtk_common, node_name, component_id
		end
	end

	context "Converge function" do
		include_context "Converge", dtk_common
	end

	context "Delete and destroy assemblies" do
		include_context "Delete assemblies", dtk_common
	end

	context "Delete module" do
		include_context "Delete module", dtk_common, module_name
	end

	context "Delete module from local filesystem" do
		include_context "Delete module from local filesystem", module_filesystem_location, module_name
	end
end