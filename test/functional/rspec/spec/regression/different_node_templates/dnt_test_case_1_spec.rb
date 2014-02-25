#!/usr/bin/env ruby
#Test Case 1: Stage existing assembly with OS ${OS} and MEMOORY_SIZE ${MEMORY_SIZE} combination and then converge it, stop the running instance (nodes) and then delete assembly

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_operations_spec'
require './lib/parameters_setting_spec'

STDOUT.sync = true

assembly_name = 'dnt_test_case_1_instance'
assembly_template = 'bootstrap::node_with_params'

os_attribute = 'os_identifier'
memory_size_attribute = 'memory_size'
OS_Memory = Struct.new(:os, :memory)
os_memory_array = [OS_Memory.new("precise","t1.micro"),OS_Memory.new("centos6.4","t1.micro")]

dtk_common = DtkCommon.new(assembly_name, assembly_template)

describe "(Different Node Templates) Test Case 1: Stage existing assembly with OS and MEMORY_SIZE combination and then converge it" do

	before(:all) do
		puts "************************************************************************************************************************"
		puts "(Different Node Templates) Test Case 1: Stage existing assembly with OS and MEMORY_SIZE combination and then converge it"
		puts "************************************************************************************************************************"
		puts ""
  	end

	os_memory_array.each do |x|
		os = x[:os]
		memory = x[:memory]

		context "For #{os} and #{memory} combination, stage assembly function on #{assembly_template} assembly template" do
			include_context "Stage", dtk_common
		end

		context "For #{os} and #{memory} combination, list assemblies after stage" do
			include_context "List assemblies after stage", dtk_common
		end		

		context "For #{os} and #{memory} combination, set OS attribute" do
			include_context "Set attribute", dtk_common, os_attribute, os
		end

		context "For #{os} and #{memory} combination, set MEMORY_SIZE attribute" do
			include_context "Set attribute", dtk_common, memory_size_attribute, memory
		end

		context "For #{os} and #{memory} combination, converge function" do
			include_context "Converge", dtk_common
		end
		
		context "For #{os} and #{memory} combination, delete and destroy assembly function" do
			include_context "Delete assemblies", dtk_common
		end
	end

	after(:all) do
		puts "", ""
	end
end