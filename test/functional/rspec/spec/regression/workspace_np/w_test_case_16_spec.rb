#!/usr/bin/env ruby
# Test Case 16: Create node group, list nodes, add component, converge workspace, inspect info output and task output and delete workspace instance
require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/workspace_spec'
require './lib/assembly_and_service_operations_spec'
require './lib/node_operations_spec'
STDOUT.sync = true

node_group_name = 'node_group'
node_image = 'precise_hvm'
node_size = 'micro'
node_cardinality = 3
node_group_attribute = 'cardinality'
component_name = 'stdlib'
component_module_namespace = 'r8'
info_to_check_1 = 'ec2_public_address'
info_to_check_2 = 'display_name: node_group'
info_to_check_3 = 'stdlib'
workspace_instance_name = 'w_test_case_16_instance'


dtk_common = Common.new('', '')

describe '(Workspace) Test Case 16: Create node group, list nodes, add component, converge workspace, inspect info output and task output and delete workspace instance' do
  before(:all) do
    puts '*************************************************************************************************************************************************************', ''
  end

  context 'Create workspace' do
    include_context 'Create workspace instance', dtk_common, workspace_instance_name
  end

  context 'Create node group' do
    include_context 'Create node group in workspace', dtk_common, node_group_name, node_image, node_size, node_cardinality
  end

  context 'Check if cardinality attribute exists' do
    include_context 'Check if attribute exists in workspace', dtk_common, node_group_name + '/' + node_group_attribute
  end

  context 'Check cardinality attribute value' do
    include_context 'Check node group cardinality', dtk_common, node_group_name, node_cardinality
  end

  context 'Add component to node group' do
    include_context 'Add component to the node in workspace', dtk_common, node_group_name, component_name, component_module_namespace
  end

  context 'Converge workspace' do
    include_context 'Converge workspace', dtk_common
  end

  node_cardinality.times do |node|
    context 'Node info' do
     include_context 'Workspace info', dtk_common, node_group_name + ":#{node + 1}", info_to_check_1
    end

    context 'Node info' do
      include_context 'Node info', dtk_common, node_group_name + ":#{node + 1}", info_to_check_2
    end
  end

  context 'Node info' do
    include_context 'Node info', dtk_common, node_group_name, info_to_check_3
  end

  context 'Delete workspace instance' do
    include_context 'Delete services', dtk_common
  end
  
  after(:all) do
    puts '', ''
  end
end