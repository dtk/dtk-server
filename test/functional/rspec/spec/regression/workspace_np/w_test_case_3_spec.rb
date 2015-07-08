#!/usr/bin/env ruby
# Test Case 3: Create one node, add component in it, converge workspace and check netstats and task info output

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/workspace_spec'

STDOUT.sync = true

node_name = 'test'
node_template = 'precise-micro'
component_name = 'stdlib'
component_module_namespace = 'r8'
port_to_check = 22

dtk_common = DtkCommon.new('', '')

describe "(Workspace) Test Case 3: Create one node, add component in it, converge workspace and check netstats and task info output" do
	before(:all) do
		puts "*************************************************************************************************************************",""
  end

	context "Create node in workspace" do
		include_context "Create node in workspace", dtk_common, node_name, node_template
	end

	context "Add component to the node in workspace" do
		include_context "Add component to the node in workspace", dtk_common, node_name, component_name, component_module_namespace
	end

	context "Converge workspace" do
		include_context "Converge workspace", dtk_common
	end

	context "Check that port #{port_to_check}" do
		include_context "Check if port avaliable", dtk_common, port_to_check
	end

	context "Purge workspace content" do
		include_context "Purge workspace content", dtk_common
	end

	after(:all) do
		puts "", ""
	end
end