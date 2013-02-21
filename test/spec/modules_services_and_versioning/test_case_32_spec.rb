#!/usr/bin/env ruby
#Test Case 32: Get list of all assembly templates for particular service

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './test/lib/dtk_common'
require './test/lib/shared_spec'

assembly_name = 'test_case_32_instance'
assembly_template = 'bootstrap::test1'
new_assembly_template = 'test_case_32_instance_assembly_template'
service_name = 'new_service'
$assembly_id = 0

dtk_common = DtkCommon.new(assembly_name, assembly_template)

puts "Test Case 32: Get list of all assembly templates for particular service"

describe "Test Case 32: Get list of all assembly templates for particular service" do

	context "Create new service function" do
		include_context "Create service", dtk_common, service_name
	end

	context "Stage assembly function" do
		include_context "Stage", dtk_common
	end

	context "List assemblies after stage" do		
		include_context "List assemblies after stage", dtk_common
	end

	context "Create assembly template in #{service_name} service from existing assembly" do
		it "missing test step implementation"
	end

	context "Check if #{new_assembly_template} assembly_template belongs to #{service_name} service" do
		include_context "Check if assembly template belongs to the service", dtk_common, service_name, new_assembly_template
	end

	context "Delete assembly template" do
		include_context "Delete assembly template", dtk_common, new_assembly_template
	end

	context "Delete and destroy assemblies" do
		include_context "Delete assemblies", dtk_common
	end

	context "List assemblies after delete" do
		include_context "List assemblies after delete", dtk_common
	end

	context "Delete service function" do
		include_context "Delete service", dtk_common, service_name
	end
end