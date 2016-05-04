#!/usr/bin/env ruby
# Test Case 4: Create two nodes, add component in both of them, converge workspace and check netstats and task info output

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/workspace_spec'
require './lib/assembly_and_service_operations_spec'

STDOUT.sync = true

node_name_1 = 'test1'
node_name_2 = 'test2'
node_template = 'precise-micro'
component_name = 'stdlib'
component_module_namespace = 'r8'
port_to_check = 22
workspace_instance_name = 'w_test_case_4_instance'

dtk_common = Common.new('', '')

describe '(Workspace) Test Case 4: Create two nodes, add component in both of them, converge workspace and check netstats and task info output' do
  before(:all) do
    puts '************************************************************************************************************************************', ''
  end

  context 'Create workspace' do
    include_context 'Create workspace instance', dtk_common, workspace_instance_name
  end

  context 'Create node in workspace' do
    include_context 'Create node in workspace', dtk_common, node_name_1, node_template
  end

  context 'Create node in workspace' do
    include_context 'Create node in workspace', dtk_common, node_name_2, node_template
  end

  context 'Add component to the node in workspace' do
    include_context 'Add component to the node in workspace', dtk_common, node_name_1, component_name, component_module_namespace
  end

  context 'Add component to the node in workspace' do
    include_context 'Add component to the node in workspace', dtk_common, node_name_2, component_name, component_module_namespace
  end

  context 'Converge workspace' do
    include_context 'Converge workspace', dtk_common
  end

  context "Check that port #{port_to_check}" do
    include_context 'Check if port avaliable on specific node in workspace', dtk_common, node_name_1, port_to_check
  end

  context "Check that port #{port_to_check}" do
    include_context 'Check if port avaliable on specific node in workspace', dtk_common, node_name_2, port_to_check
  end

  context 'Delete workspace instance' do
    include_context 'Delete services', dtk_common
  end

  after(:all) do
    puts '', ''
  end
end
