#!/usr/bin/env ruby
# Test Case 6: Create one node, add two components in it (list components), delete one component (list components again) and purge workspace content

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
component_name_1 = 'bootstrap::sink'
component_name_2 = 'bootstrap::source'
component_module_namespace = 'r8'

dtk_common = Common.new('', '')

describe '(Workspace) Test Case 6: Create one node, add two components in it (list components), delete one component (list components again) and purge workspace content' do
  before(:all) do
    puts '**************************************************************************************************************************************************************', ''
  end

  context 'Create node in workspace' do
    include_context 'Create node in workspace', dtk_common, node_name, node_template
  end

  context 'Add component to the node in workspace' do
    include_context 'Add component to the node in workspace', dtk_common, node_name, component_name_1, component_module_namespace
  end

  context 'Add component to the node in workspace' do
    include_context 'Add component to the node in workspace', dtk_common, node_name, component_name_2, component_module_namespace
  end

  context 'List components in workspace node' do
    include_context 'List components in workspace node', dtk_common, node_name, component_name_1
  end

  context 'List components in workspace node' do
    include_context 'List components in workspace node', dtk_common, node_name, component_name_2
  end

  context 'Delete component from workspace node' do
    include_context 'Delete component from workspace node', dtk_common, node_name, component_name_1
  end

  context 'NEG - List components in workspace node' do
    include_context 'NEG - List components in workspace node', dtk_common, node_name, component_name_1
  end

  context 'List components in workspace node' do
    include_context 'List components in workspace node', dtk_common, node_name, component_name_2
  end

  context 'Purge workspace content' do
    include_context 'Purge workspace content', dtk_common
  end

  after(:all) do
    puts '', ''
  end
end
