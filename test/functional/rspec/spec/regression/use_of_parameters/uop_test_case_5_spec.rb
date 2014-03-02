#!/usr/bin/env ruby
#Test Case 5: Change optional params on existing attributes in service nodes (values were previously defined)

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/parameters_setting_spec'

service_name = 'uop_test_case_5_instance'
assembly_name = 'bootstrap::node_with_params'
os = 'precise'
memory_size = 't1.micro'
node_name = 'node1'
cent_os = "centos6.4"
centos_memory_size = 'm1.small'

dtk_common = DtkCommon.new(service_name, assembly_name)

describe "(Use Of Parameters) Test Case 5: Change optional params on existing attributes in service nodes (values were previously defined)" do

	before(:all) do
		puts "********************************************************************************************************************************"
		puts "(Use Of Parameters) Test Case 5: Change optional params on existing attributes in service nodes (values were previously defined)"
		puts "********************************************************************************************************************************"
    puts ""
	end

	context "Stage service function on #{assembly_name} assembly" do
		include_context "Stage", dtk_common
	end

	context "List services after stage" do		
		include_context "List services after stage", dtk_common
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

	context "Set os attribute function with different value #{cent_os}" do
		include_context "Set attribute", dtk_common, 'os_identifier', cent_os
	end

	context "Set memory_size attribute function with different value #{centos_memory_size}" do
		include_context "Set attribute", dtk_common, 'memory_size', centos_memory_size
	end

	context "Converge function again" do
		include_context "Converge", dtk_common
	end	

	context "Check changed os attribute after converge" do
		include_context "Check attribute", dtk_common, node_name, 'os_identifier', cent_os
	end

	context "Check changed memory_size attribute after converge" do
		include_context "Check attribute", dtk_common, node_name, 'memory_size', centos_memory_size
	end

	context "Delete and destroy service function" do
		include_context "Delete services", dtk_common
	end
	
	after(:all) do
		puts "", ""
	end
end