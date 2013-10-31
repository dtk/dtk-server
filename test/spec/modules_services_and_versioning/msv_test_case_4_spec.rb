#!/usr/bin/env ruby
#Test Case 4: Get list of all assembly templates for particular service

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'
require './lib/services_spec'

assembly_name = 'msv_test_case_4_instance'
assembly_template = 'bootstrap::test1'
new_assembly_template = 'msv_test_case_4_temp'
service_filesystem_location = '~/dtk/service_modules'
service_name = 'new_service'
$assembly_id = 0

dtk_common = DtkCommon.new(assembly_name, assembly_template)

describe "(Modules, Services and Versioning) Test Case 4: Get list of all assembly templates for particular service" do

	before(:all) do
		puts "*********************************************************************************************************"
		puts "(Modules, Services and Versioning) Test Case 4: Get list of all assembly templates for particular service"
		puts "*********************************************************************************************************"
    puts ""
	end

	context "Create new service function" do
		include_context "Create service", dtk_common, service_name
	end

	context "Stage assembly function on #{assembly_template} assembly template" do
		include_context "Stage", dtk_common
	end

	context "List assemblies after stage" do		
		include_context "List assemblies after stage", dtk_common
	end

	context "Create assembly template from existing assembly" do
		include_context "Create assembly template from assembly", dtk_common, service_name, new_assembly_template
	end

	context "Check if #{new_assembly_template} assembly_template belongs to #{service_name} service" do
		include_context "Check if assembly template belongs to the service", dtk_common, service_name, new_assembly_template
	end

	context "Delete assembly template" do
		include_context "Delete assembly template", dtk_common, "#{service_name}::#{new_assembly_template}"
	end

	context "Delete and destroy assembly function" do
		include_context "Delete assemblies", dtk_common
	end

	context "List assemblies after delete" do
		include_context "List assemblies after delete", dtk_common
	end

	context "Delete service function" do
		include_context "Delete service", dtk_common, service_name
	end

	context "Delete service from local filesystem" do
    include_context "Delete service from local filesystem", service_filesystem_location, service_name
  end

	after(:all) do
		puts "", ""
	end
end