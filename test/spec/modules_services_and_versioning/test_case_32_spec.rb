#!/usr/bin/env ruby
#Test Case 32: Get list of all assembly templates for particular service

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'
require './lib/services_spec'

assembly_name = 'test_case_32_instance'
assembly_template = 'bootstrap::test1'
new_assembly_template = 'test_case_32_temp'
service_name = 'new_service'
$assembly_id = 0

dtk_common = DtkCommon.new(assembly_name, assembly_template)

puts "***********************************************************************"
puts "Test Case 32: Get list of all assembly templates for particular service"
puts "***********************************************************************"

describe "Test Case 32: Get list of all assembly templates for particular service" do

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
end

puts "", ""