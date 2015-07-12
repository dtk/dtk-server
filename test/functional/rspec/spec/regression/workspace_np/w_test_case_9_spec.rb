#!/usr/bin/env ruby
# Test Case 9: Create two nodes, add components in both of them, and create assembly from the workspace content in new service module

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
service_module_name = 'new_bootstrap'
local_service_module_name = 'local:new_bootstrap'
namespace = 'local'
service_module_filesystem_location = '~/dtk/service_modules/local'
assembly_name = 'workspace_assembly'

dtk_common = Common.new('', '')

describe "(Workspace) Test Case 9: Create two nodes, add components in both of them, and create assembly from the workspace content in new service module" do

	before(:all) do
		puts "***********************************************************************************************************************************************",""
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

	context "NEG - List all service modules" do
		include_context "NEG - List all service modules", dtk_common, service_module_name
	end

	context "Create assembly from workspace content" do
		include_context "Create assembly from workspace content", dtk_common, service_module_name, assembly_name, namespace
	end

	context "Check if assembly belongs to the service module" do
		include_context "Check if assembly belongs to the service module", dtk_common, local_service_module_name, assembly_name
	end

	context "Delete assembly" do
		include_context "Delete assembly", dtk_common, "#{service_module_name}/#{assembly_name}", namespace
	end

	context "Delete service module function" do
		include_context "Delete service module", dtk_common, local_service_module_name
	end

	context "Delete service module from local filesystem" do
    	include_context "Delete service module from local filesystem", service_module_filesystem_location, service_module_name
  	end

	context "Purge workspace content" do
		include_context "Purge workspace content", dtk_common
	end	

	after(:all) do
		puts "", ""
	end
end