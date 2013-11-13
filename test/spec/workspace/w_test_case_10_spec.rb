#!/usr/bin/env ruby
#Test Case 10: Create two nodes, add components in both of them, and create assembly from the workspace content in existing service, stage and converge this assembly template

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
service_filesystem_location = '~/dtk/service_modules'
assembly_template_name = 'workspace_assembly_template'
assembly_template = 'bootstrap::workspace_assembly_template'
assembly_name = 'w_test_case_10_instance'

dtk_common = DtkCommon.new(assembly_name, assembly_template)

describe "(Workspace) Test Case 10: Create two nodes, add components in both of them, and create assembly from the workspace content in existing service, stage and converge this assembly template" do

	before(:all) do
		puts "*****************************************************************************************************************************************************************************************"
		puts "(Workspace) Test Case 10: Create two nodes, add components in both of them, and create assembly from the workspace content in existing service, stage and converge this assembly template"
		puts "*****************************************************************************************************************************************************************************************"
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

	context "Stage assembly function on #{assembly_template} assembly template" do
		include_context "Stage", dtk_common
	end

	context "List assemblies after stage" do		
		include_context "List assemblies after stage", dtk_common
	end

	context "Converge function" do
		include_context "Converge", dtk_common
	end

	context "Delete and destroy assembly function" do
		include_context "Delete assemblies", dtk_common
	end

	context "Delete assembly template" do
		include_context "Delete assembly template", dtk_common, assembly_template
	end

	context "Purge workspace content" do
		include_context "Purge workspace content", dtk_common
	end	

	after(:all) do
		puts "", ""
	end
end