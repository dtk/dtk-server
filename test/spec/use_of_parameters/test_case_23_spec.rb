#!/usr/bin/env ruby
#Test Case 23: Add optional params on existing attributes in assembly nodes (values were not defined)

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './test/lib/dtk_common'
require './test/lib/shared_spec'

assembly_name = 'test_case_23_instance'
assembly_template = 'bootstrap::node_with_params'
OS = 'natty'
MEMORY_SIZE = 't1.micro'
HOST_ADDRESSES_IPV4 = '127.0.0.1'
NODE_NAME = 'node1'

$assembly_id = 0
dtk_common = DtkCommon.new(assembly_name, assembly_template)

describe "Test Case 23: Add optional params on existing attributes in assembly nodes (values were not defined)" do

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

	context "Set HOST_ADDRESSES_IPV4 attribute function" do
		include_context "Set attribute", dtk_common, 'host_addresses_ipv4', HOST_ADDRESSES_IPV4
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

	context "Check HOST_ADDRESSES_IPV4 attribute function" do
		include_context "Check attribute", dtk_common, NODE_NAME, 'host_addresses_ipv4', HOST_ADDRESSES_IPV4
	end

	context "Delete and destroy assemblies" do
		include_context "Delete assemblies", dtk_common
	end
end