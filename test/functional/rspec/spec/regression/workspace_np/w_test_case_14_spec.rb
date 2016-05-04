#!/usr/bin/env ruby
# Test Case 14: Create two nodes, add components in it, converge, stop both nodes and then start again

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

dtk_common = Common.new('', '')

describe '(Workspace) Test Case 14: Create two nodes, add components in it, converge, stop both nodes and then start again' do
  before(:all) do
    puts '****************************************************************************************************************', ''
  end

  context 'Create workspace' do
    include_context 'Create workspace instance', dtk_common, 'w_test_case_14_instance'
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

  context 'Stop workspace' do
    include_context 'Stop workspace', dtk_common
  end

  context 'Start workspace' do
    sleep 10 #Just to make sure nodes are stopped on aws
    include_context 'Start workspace', dtk_common
  end

  context 'Delete workspace instance' do
    include_context 'Delete services', dtk_common
  end

  after(:all) do
    puts '', ''
  end
end
