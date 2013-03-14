#!/usr/bin/env ruby
#Test Case 28: Import component module from remote and use this component in assembly

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/shared_spec'

assembly_name = 'test_case_28_instance'
assembly_template = 'bootstrap::node_with_params'
os = 'natty'
node_name = 'node1'
module_name = "mysql"
module_filesystem_location = "~/component_modules"
$assembly_id = 0
#Initial empty module components list, will be populated after "Get module components list" context call
$module_components_list = Array.new()

dtk_common = DtkCommon.new(assembly_name, assembly_template)

puts "Test Case 28: Import component module from remote and use this component in assembly"

describe "Test Case 28: Import component module from remote and use this component in assembly" do

	context "Import module #{module_name} function" do
		include_context "Import remote module", module_name
	end

	context "Get module components list" do
		include_context "Get module components list", dtk_common, module_name
	end

	context "Check if module imported on local filesystem" do
		include_context "Check module imported on local filesystem", module_filesystem_location, module_name
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

	context "Add components to assembly node" do
		$module_components_list.each do |component_id|
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