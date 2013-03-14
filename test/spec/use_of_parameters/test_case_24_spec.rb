#!/usr/bin/env ruby
#Test Case 24: Change optional params on existing attributes in assembly nodes (values were previously defined)

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/shared_spec'

assembly_name = 'test_case_24_instance'
assembly_template = 'bootstrap::node_with_params'
OS = 'natty'
MEMORY_SIZE = 't1.micro'
NODE_NAME = 'node1'

$assembly_id = 0
dtk_common = DtkCommon.new(assembly_name, assembly_template)

describe "Test Case 24: Change optional params on existing attributes in assembly nodes (values were previously defined)" do

	context "Stage assembly function" do
		include_context "Stage", dtk_common
	end

	context "List assemblies after stage" do		
		include_context "List assemblies after stage", dtk_common
	end

	context "Set OS attribute function" do
		include_context "Set attribute", dtk_common, 'os_identifier', OS
	end

	context "Set MEMORY_SIZE attribute function" do
		include_context "Set attribute", dtk_common, 'memory_size', MEMORY_SIZE
	end

	context "Converge function" do
		include_context "Converge", dtk_common
	end

	context "Check OS attribute function after converge" do
		include_context "Check attribute", dtk_common, NODE_NAME, 'os_identifier', OS
	end

	context "Check MEMORY_SIZE attribute function after converge" do
		include_context "Check attribute", dtk_common, NODE_NAME, 'memory_size', MEMORY_SIZE
	end

	context "Set OS attribute function with different value" do
		include_context "Set attribute", dtk_common, 'os_identifier', 'rh5.7-64'
	end

	context "Set MEMORY_SIZE attribute function with different value" do
		include_context "Set attribute", dtk_common, 'memory_size', 'm1.small'
	end

	context "Converge function again" do
		include_context "Converge", dtk_common
	end	

	context "Check changed OS attribute function after converge" do
		include_context "Check attribute", dtk_common, NODE_NAME, 'os_identifier', 'rh5.7-64'
	end

	context "Check changed MEMORY_SIZE attribute function after converge" do
		include_context "Check attribute", dtk_common, NODE_NAME, 'memory_size', 'm1.small'
	end

	context "Delete and destroy assemblies" do
		include_context "Delete assemblies", dtk_common
	end
end