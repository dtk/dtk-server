#!/usr/bin/env ruby
# Test Case 11: Create two nodes, add components in both of them, link attributes between components on different nodes and check if value is propagated

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
component_name_1 = 'common_user[test]'
component_name_2 = 'common_user::common_user_ssh_config[test]'
attribute_name_1 = 'common_user[test]/user'
attribute_value = 'new_user'
attribute_name_2 = 'common_user::common_user_ssh_config[test]/user'

dtk_common = Common.new('', '')

describe '(Workspace) Test Case 11: Create two nodes, add components in both of them, link attributes between components on different nodes and check if value is propagated' do
  before(:all) do
    puts '******************************************************************************************************************************************************************'
    puts '(Workspace) Test Case 11: Create two nodes, add components in both of them, link attributes between components on different nodes and check if value is propagated'
    puts '******************************************************************************************************************************************************************'
    puts ''
    end

  context 'Create node in workspace' do
    include_context 'Create node in workspace', dtk_common, node_name_1, node_template
  end

  context 'Create node in workspace' do
    include_context 'Create node in workspace', dtk_common, node_name_2, node_template
  end

  context 'Add component to the node in workspace' do
    include_context 'Add component to the node in workspace', dtk_common, node_name_1, component_name_1
  end

  context 'Add component to the node in workspace' do
    include_context 'Add component to the node in workspace', dtk_common, node_name_2, component_name_2
  end

  context 'Check if attribute exists in workspace' do
    include_context 'Check if attribute exists in workspace', dtk_common, "#{node_name_1}/#{attribute_name_1}"
  end

  context 'Check if attribute exists in workspace' do
    include_context 'Check if attribute exists in workspace', dtk_common, "#{node_name_2}/#{attribute_name_2}"
  end

  context 'Link attributes' do
    include_context 'Link attributes', dtk_common, "#{node_name_1}/#{attribute_name_1}", "#{node_name_2}/#{attribute_name_2}"
  end

  context 'Set attribute value in workspace' do
    include_context 'Set attribute value in workspace', dtk_common, "#{node_name_1}/#{attribute_name_1}", attribute_value
  end

  context 'Check if value for attribute is set' do
    include_context 'Check if value for attribute is set', dtk_common, node_name_1, attribute_name_1, attribute_value
  end

  context 'Check if value for attribute is set' do
    include_context 'Check if value for attribute is set', dtk_common, node_name_2, attribute_name_2, attribute_value
  end

  context 'Purge workspace content' do
    include_context 'Purge workspace content', dtk_common
  end

  after(:all) do
    puts '', ''
  end
end
