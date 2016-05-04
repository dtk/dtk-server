#!/usr/bin/env ruby
# Test Case 5: Create two nodes (list nodes), delete one node (list nodes again) and purge workspace content

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
workspace_instance_name = 'w_test_case_5_instance'

dtk_common = Common.new('', '')

describe '(Workspace) Test Case 5: Create two nodes (list nodes), delete one node (list nodes again) and purge workspace content' do
  before(:all) do
    puts '**********************************************************************************************************************', ''
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

  context 'Check node in workspace' do
    include_context 'Check node in workspace', dtk_common, node_name_1
  end

  context 'Check node in workspace' do
    include_context 'Check node in workspace', dtk_common, node_name_2
  end

  context 'Delete node in workspace' do
    include_context 'Delete node in workspace', dtk_common, node_name_1
  end

  context 'NEG - Check node in workspace' do
    include_context 'NEG - Check node in workspace', dtk_common, node_name_1
  end

  context 'Check node in workspace' do
    include_context 'Check node in workspace', dtk_common, node_name_2
  end

  context 'Delete workspace instance' do
    include_context 'Delete services', dtk_common
  end

  after(:all) do
    puts '', ''
  end
end
