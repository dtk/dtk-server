#!/usr/bin/env ruby
# Test Case 12: Create one node, add component in it, converge workspace and grep puppet log from node

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/workspace_spec'
require './lib/assembly_and_service_operations_spec'

STDOUT.sync = true

node_name = 'test'
node_template = 'precise-micro'
component_name = 'stdlib'
component_module_namespace = 'r8'
puppet_log_location = '/usr/share/dtk/tasks/last-task/site-stage.log'
grep_pattern = 'transaction'

dtk_common = Common.new('', '')

describe '(Workspace) Test Case 12: Create one node, add component in it, converge workspace and grep puppet log from node' do
  before(:all) do
    puts '****************************************************************************************************************', ''
  end

  context 'Create workspace' do
    include_context 'Create workspace instance', dtk_common, 'w_test_case_12_instance'
  end

  context 'Create node in workspace' do
    include_context 'Create node in workspace', dtk_common, node_name, node_template
  end

  context 'Add component to the node in workspace' do
    include_context 'Add component to the node in workspace', dtk_common, node_name, component_name, component_module_namespace
  end

  context 'Converge workspace' do
    include_context 'Converge workspace', dtk_common
  end

  context 'Grep command on puppet log' do
    include_context 'Grep log command in workspace', dtk_common, node_name, puppet_log_location, grep_pattern
  end

  context 'Delete workspace instance' do
    include_context 'Delete services', dtk_common
  end

  after(:all) do
    puts '', ''
  end
end
