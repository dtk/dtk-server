#!/usr/bin/env ruby
#Test Case 35: Import new module from remote repo and then import same version-ed module from remote

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './test/lib/dtk_common'
require './test/lib/shared_spec'

assembly_name = 'test_case_35_instance'
assembly_template = 'bootstrap::test1'
module_name = 'test'
module_version = '0.0.1'
module_filesystem_location = "~/component_modules"
$assembly_id = 0

#Initial empty module components list, will be populated after "Get module components list" context call
$module_components_list = Array.new()
#Initial empty versioned module component list, will be populated after "Get versioned module components list" context call
$versioned_module_components_list = Array.new()

dtk_common = DtkCommon.new(assembly_name, assembly_template)

describe "Test Case 35: Import new module from remote repo and then import same version-ed module from remote" do

	context "Import module #{module_name} function" do
		#include_context "Import remote module", dtk_common, module_name
		it "test" do
			pass = false
			value = `dtk module import #{module_name}`	
			pass = value.include? "module_directory:"
			pass.should eq(true)
		end
	end

	context "Get module components list" do
		include_context "Get module components list", dtk_common, module_name
	end

	context "Import versioned module from remote function" do
		include_context "Import versioned module from remote", dtk_common, module_name, module_version
	end

	context "Get versioned module components list" do
		include_context "Get versioned module components list", dtk_common, module_name, module_version
	end

	context "Delete module" do
		include_context "Delete module", dtk_common, module_name
	end

=begin 
	#Not used now in the script
	context "Delete module from local filesystem" do
		it "deletes module" do
			delete_response = system("rm -rf #{module_filesystem_location}/#{module_name}")
			delete_response.should eq(true)
		end
	end

	context "Delete versioned module from local filesystem" do
		it "deletes versioned module" do
			delete_response = system("rm -rf #{module_filesystem_location}/#{module_name}-#{module_version}")
			delete_response.should eq(true)
		end
	end
=end
end