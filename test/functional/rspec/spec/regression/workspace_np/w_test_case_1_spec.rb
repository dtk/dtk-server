#!/usr/bin/env ruby
# Test Case 1: Create one node, add component in it, converge workspace, inspect info output and task output and purge workspace content

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
info_to_check_1 = 'ec2_public_address'
info_to_check_2 = 'display_name: test'
info_to_check_3 = 'stdlib'
workspace_instance_name = 'w_test_case_1_instance'

dtk_common = Common.new('', '')

describe '(Workspace) Test Case 1: Create one node, add component in it, converge workspace, inspect info output and task output and purge workspace content' do
  before(:all) do
    puts '**************************************************************************************************************************************************', ''
  end

  context 'Create workspace' do
    include_context 'Create workspace instance', dtk_common, workspace_instance_name
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

  context 'Workspace info' do
    include_context 'Workspace info', dtk_common, info_to_check_1
  end

  context 'Workspace info' do
    include_context 'Workspace info', dtk_common, info_to_check_2
  end

  context 'Workspace info' do
    include_context 'Workspace info', dtk_common, info_to_check_3
  end

  context 'Delete workspace instance' do
    include_context 'Delete services', dtk_common
  end

  after(:all) do
    puts '', ''
  end
end
