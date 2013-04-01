#!/usr/bin/env ruby
#Test Case 33: Clone existing module to local filesystem, do some change on it and use push-clone-changes to push changes from local copy to server

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'
require './lib/parameters_setting_spec'
require './lib/modules_spec'

assembly_name = 'test_case_33_instance'
assembly_template = 'bootstrap::test1'
module_name = 'mysql'
module_version = '0.0.1'
module_filesystem_location = "~/component_modules"
file_for_change = "README.md"
$assembly_id = 0

#Initial empty module components list, will be populated after "Get module components list" context call
$module_components_list = Array.new()
#Initial empty versioned module component list, will be populated after "Get versioned module components list" context call
$versioned_module_components_list = Array.new()

dtk_common = DtkCommon.new(assembly_name, assembly_template)

puts "**************************************************************************************************************************************************"
puts "Test Case 33: Clone existing module to local filesystem, do some change on it and use push-clone-changes to push changes from local copy to server"
puts "**************************************************************************************************************************************************"

describe "Test Case 33: Clone existing module to local filesystem, do some change on it and use push-clone-changes to push changes from local copy to server" do

	context "Import module function" do
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

	context "Append comment to the readme file in module contents to see effect of push-clone-change" do
		it "appends comment to readme file" do
			pass = true
			`echo "# Mysql module for Puppet" >> #{module_filesystem_location}/#{module_name}-#{module_version}/#{file_for_change}`
			pass.should eq(true)
		end
	end

	context "Push clone changes of versioned module from local copy to server" do
		it "pushes clone changes of #{module_name} module for version #{module_version}" do
			pass = false
			value = `dtk module #{module_name} push-clone-changes -v #{module_version}`
			pass = value.include?("#{file_for_change}")
			pass.should eq(true)
		end
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

puts "", ""