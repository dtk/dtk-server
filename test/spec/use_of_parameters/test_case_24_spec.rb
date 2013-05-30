#!/usr/bin/env ruby
#Test Case 24: Change optional params on existing attributes in assembly nodes (values were previously defined)

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'
require './lib/parameters_setting_spec.rb'

assembly_name = 'test_case_24_instance'
assembly_template = 'bootstrap::node_with_params'
os = 'natty'
memory_size = 't1.micro'
node_name = 'node1'
rhel_os = "rh5.7-64"
rhel_memory_size = 'm1.small'

$assembly_id = 0
dtk_common = DtkCommon.new(assembly_name, assembly_template)

describe "Test Case 24: Change optional params on existing attributes in assembly nodes (values were previously defined)" do

	before(:all) do
		puts "**************************************************************************************************************"
		puts "Test Case 24: Change optional params on existing attributes in assembly nodes (values were previously defined)"
		puts "**************************************************************************************************************"
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

	context "Set os attribute function with different value #{rhel_os}" do
		include_context "Set attribute", dtk_common, 'os_identifier', rhel_os
	end

	context "Set memory_size attribute function with different value #{rhel_memory_size}" do
		include_context "Set attribute", dtk_common, 'memory_size', rhel_memory_size
	end

	context "Converge function again" do
		include_context "Converge", dtk_common
	end	

	context "Check changed os attribute after converge" do
		include_context "Check attribute", dtk_common, node_name, 'os_identifier', rhel_os
	end

	context "Check changed memory_size attribute after converge" do
		include_context "Check attribute", dtk_common, node_name, 'memory_size', rhel_memory_size
	end

	context "Delete and destroy assembly function" do
		include_context "Delete assemblies", dtk_common
	end
	
	after(:all) do
		puts "", ""
	end
end