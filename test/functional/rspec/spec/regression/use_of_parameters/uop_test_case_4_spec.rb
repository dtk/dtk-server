#!/usr/bin/env ruby
#Test Case 4: Add optional params on existing attributes in assembly nodes (values were not defined)

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'
require './lib/parameters_setting_spec.rb'

assembly_name = 'uop_test_case_4_instance'
assembly_template = 'bootstrap::node_with_params'
os = 'precise'
memory_size = 't1.micro'
node_name = 'node1'

$assembly_id = 0
dtk_common = DtkCommon.new(assembly_name, assembly_template)

describe "(Use Of Parameters) Test Case 4: Add optional params on existing attributes in assembly nodes (values were not defined)" do

	before(:all) do
		puts "***********************************************************************************************************************"
		puts "(Use Of Parameters) Test Case 4: Add optional params on existing attributes in assembly nodes (values were not defined)"
		puts "***********************************************************************************************************************"
    puts ""
	end

	context "Stage assembly function on #{assembly_template} assembly template" do
		include_context "Stage", dtk_common
	end

	context "List assemblies after stage" do		
		include_context "List assemblies after stage", dtk_common
	end

	context "Set os attribute function" do
		include_context "Set attribute", dtk_common, 'os_identifier', os
	end

	context "Set memory_size attribute function" do
		include_context "Set attribute", dtk_common, 'memory_size', memory_size
	end

	context "Converge function" do
		include_context "Converge", dtk_common
	end

	context "Check os attribute after converge" do
		include_context "Check attribute", dtk_common, node_name, 'os_identifier', os
	end

	context "Check memory_size attribute after converge" do
		include_context "Check attribute", dtk_common, node_name, 'memory_size', memory_size
	end

	context "Delete and destroy assembly function" do
		include_context "Delete assemblies", dtk_common
	end

	after(:all) do
		puts "", ""
	end
end