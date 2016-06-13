#!/usr/bin/env ruby
# Test Case 18: Stage service and then try to delete component, delete node and delete service workflow

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/node_operations_spec'

STDOUT.sync = true

namespace = 'dtk17'
service_module_name = 'test_delete'
component_module_name = 'test_delete'
service_name = 'stda_test_case_18_instance'
assembly_name = 'test_delete::delete_workflow'
components_to_delete = "test_delete::component"
node_name = 'node'
node_template = 'trusty_hvm-micro'
check_component_in_task_status = false
dtk_common = Common.new(service_name, assembly_name)

describe '(Staging And Deploying Assemblies) Test Case 18: Stage service and then try to delete component, delete node and delete service workflow' do
  before(:all) do
    puts '****************************************************************************************************************************************', ''
  end

  context "Stage service function on #{assembly_name} assembly" do
    include_context 'Stage', dtk_common
  end

  context 'List services after stage' do
    include_context 'List services after stage', dtk_common
  end

  context 'Delete component with workflow' do
    include_context 'Delete component with workflow', dtk_common, node_name, components_to_delete, check_component_in_task_status
  end

  context 'Add component to node' do
    include_context 'Add component to node', dtk_common, node_name, 'test_delete::component', namespace
  end

  context 'Delete node with workflow' do
    include_context 'Delete node with workflow', dtk_common, node_name, components_to_delete, check_component_in_task_status
  end

  context 'List nodes after delete node' do
    include_context 'NEG - List nodes', dtk_common, node_name
  end

  context 'Create node' do
    include_context 'Create node', dtk_common, node_name, node_template
  end

  context 'Add component to node' do
    include_context 'Add component to node', dtk_common, node_name, 'test_delete::component', namespace
  end

  context 'Delete and destroy service with workflow' do
    include_context 'Delete service with workflow', dtk_common, components_to_delete, check_component_in_task_status
  end

  context 'List services after delete' do
    include_context 'List services after delete', dtk_common
  end

  after(:all) do
    puts '', ''
  end
end