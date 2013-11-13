#!/usr/bin/env ruby
#Test Case 8: Create two nodes, add components in both of them, and create assembly from the workspace content in existing service

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/workspace_spec'
require './lib/services_spec'
require './lib/assembly_operations_spec'

STDOUT.sync = true

node_name_1 = 'test1'
node_name_2 = 'test2'
node_template = 'precise-micro'
component_name = 'stdlib'
service_name = 'bootstrap'
assembly_template_name = 'workspace_assembly_template'

dtk_common = DtkCommon.new('', '')

describe "(Workspace) Test Case 8: Create two nodes, add components in both of them, and create assembly from the workspace content in existing service" do

	before(:all) do
		puts "*********************************************************************************************************************************************"
		puts "(Workspace) Test Case 8: Create two nodes, add components in both of them, and create assembly from the workspace content in existing service"
		puts "*********************************************************************************************************************************************"
		puts ""
  	end

	context "Create node in workspace" do
		include_context "Create node in workspace", dtk_common, node_name_1, node_template
	end

	context "Create node in workspace" do
		include_context "Create node in workspace", dtk_common, node_name_2, node_template
	end

	context "Add component to the node in workspace" do
		include_context "Add component to the node in workspace", dtk_common, node_name_1, component_name
	end	

	context "Add component to the node in workspace" do
		include_context "Add component to the node in workspace", dtk_common, node_name_2, component_name
	end	

	context "Create assembly template from workspace content" do
		include_context "Create assembly template from workspace content", dtk_common, service_name, assembly_template_name
	end

	context "Check if assembly template belongs to the service" do
		include_context "Check if assembly template belongs to the service", dtk_common, service_name, assembly_template_name
	end

	context "Delete assembly template" do
		include_context "Delete assembly template", dtk_common, "#{service_name}::#{assembly_template_name}"
	end

	context "Purge workspace content" do
		include_context "Purge workspace content", dtk_common
	end	

	after(:all) do
		puts "", ""
	end
end