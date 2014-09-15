#!/usr/bin/env ruby
# Test Case 10: Create two nodes, add components in both of them, and create assembly from the workspace content in existing service module, stage and converge this assembly

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/workspace_spec'
require './lib/service_modules_spec'
require './lib/assembly_and_service_operations_spec'

STDOUT.sync = true

node_name_1 = 'test1'
node_name_2 = 'test2'
node_template = 'precise-micro'
component_name = 'stdlib'
component_module_namespace = 'r8'
service_module_name = 'bootstrap'
local_service_module_name = 'r8:bootstrap'
namespace = 'r8'
service_module_filesystem_location = '~/dtk/service_modules'
assembly = 'workspace_assembly'
assembly_name = 'bootstrap::workspace_assembly'
service_name = 'w_test_case_10_instance'

dtk_common = DtkCommon.new(service_name, assembly_name)

describe "(Workspace) Test Case 10: Create two nodes, add components in both of them, and create assembly from the workspace content in existing service module, stage and converge this assembly" do

	before(:all) do
		puts "***************************************************************************************************************************************************************************************",""
  end

	context "Create node in workspace" do
		include_context "Create node in workspace", dtk_common, node_name_1, node_template
	end

	context "Create node in workspace" do
		include_context "Create node in workspace", dtk_common, node_name_2, node_template
	end

	context "Add component to the node in workspace" do
		include_context "Add component to the node in workspace", dtk_common, node_name_1, component_name, component_module_namespace
	end	

	context "Add component to the node in workspace" do
		include_context "Add component to the node in workspace", dtk_common, node_name_2, component_name, component_module_namespace
	end	

	context "Create assembly from workspace content" do
		include_context "Create assembly from workspace content", dtk_common, service_module_name, assembly
	end

	context "Check if assembly belongs to the service module" do
		include_context "Check if assembly belongs to the service module", dtk_common, local_service_module_name, assembly
	end

	context "Stage service function on #{assembly_name} assembly" do
		include_context "Stage", dtk_common
	end

	context "List services after stage" do		
		include_context "List services after stage", dtk_common
	end

	context "Converge function" do
		include_context "Converge", dtk_common
	end

	context "Delete and destroy service function" do
		include_context "Delete services", dtk_common
	end

	context "Delete assembly" do
		include_context "Delete assembly", dtk_common, assembly_name, namespace
	end

	context "Purge workspace content" do
		include_context "Purge workspace content", dtk_common
	end	

	after(:all) do
		puts "", ""
	end
end