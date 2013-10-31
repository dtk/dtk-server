#!/usr/bin/env ruby
#Test Case 7: Import new module from remote repo and then import same version-ed module from remote

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/modules_spec'

assembly_name = 'msv_test_case_7_instance'
assembly_template = 'bootstrap::test1'
module_name = 'test'
module_version = '0.0.1'
module_namespace = "dtk17"
module_filesystem_location = "~/dtk/component_modules"
$assembly_id = 0

dtk_common = DtkCommon.new(assembly_name, assembly_template)

describe "(Modules, Services and Versioning) Test Case 7: Import new module from remote repo and then import same version-ed module from remote" do

	before(:all) do
		puts "*************************************************************************************************************************************"
		puts "(Modules, Services and Versioning) Test Case 7: Import new module from remote repo and then import same version-ed module from remote"
		puts "*************************************************************************************************************************************"
    puts ""
	end

	context "Import module function" do
		include_context "Import remote module", module_namespace + "/" + module_name
	end

	context "Get module components list" do
		include_context "Get module components list", dtk_common, module_name
	end

	context "Check if module imported on local filesystem" do
		include_context "Check module imported on local filesystem", module_filesystem_location, module_name
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

	context "Delete module from local filesystem" do
		include_context "Delete module from local filesystem", module_filesystem_location, module_name
	end

	context "Delete versioned module from local filesystem" do
		include_context "Delete versioned module from local filesystem", module_filesystem_location, module_name, module_version
	end

	after(:all) do
		puts "", ""
	end
end

