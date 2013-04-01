#!/usr/bin/env ruby
#Test Case 4: Deploy from assembly template (stage and converge), stop the running instance (nodes) and then delete assembly

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'
require './lib/parameters_setting_spec'

STDOUT.sync = true

assembly_name = 'test_case_4_instance'
assembly_template = 'bootstrap::node_with_params'
os = 'natty'
os_attribute = 'os_identifier'
memory_size = 't1.micro'
memory_size_attribute = 'memory_size'

$assembly_id = 0
dtk_common = DtkCommon.new(assembly_name, assembly_template)

describe "Test Case 4: Deploy from assembly template (stage and converge), stop the running instance (nodes) and then delete assembly" do

	before(:all) do
		puts "***************************************************************************************************************************"
		puts "Test Case 4: Deploy from assembly template (stage and converge), stop the running instance (nodes) and then delete assembly"
		puts "***************************************************************************************************************************"
		puts ""
	end

	context "Stage assembly function on #{assembly_template} assembly template" do
		include_context "Stage", dtk_common
	end

	context "List assemblies after stage" do
		include_context "List assemblies after stage", dtk_common
	end

	context "Set os attribute function" do
		include_context "Set attribute", dtk_common, os_attribute, os
	end

	context "Set Memory attribute function" do
		include_context "Set attribute", dtk_common, memory_size_attribute, memory_size
	end

	context "Converge function" do
		include_context "Converge", dtk_common
	end

	context "Stop assembly function" do
		include_context "Stop assembly", dtk_common
	end	

	context "Delete and destroy assembly function" do
		include_context "Delete assemblies", dtk_common
	end

	after(:all) do
		puts "", ""
	end
end