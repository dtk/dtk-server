#!/usr/bin/env ruby
# Test Case 1: Import component module from remote and use this component in assembly

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/parameters_setting_spec'
require './lib/component_modules_spec'

service_name = 'msv_test_case_1_instance'
assembly_name = 'bootstrap::node_with_params'
os = 'precise'
os_attribute = 'os_identifier'
node_name = 'node1'
component_module_name = 'test_module'
component_module_namespace = 'dtk17'
local_component_module_name = 'dtk17:test_module'
component_module_filesystem_location = '~/dtk/component_modules/dtk17'

dtk_common = DtkCommon.new(service_name, assembly_name)

describe '(Modules, Services and Versioning) Test Case 1: Import component module from remote and use this component in assembly' do
  before(:all) do
    puts '**********************************************************************************************************************', ''
  end

  context 'Import component module function' do
    include_context 'Import remote component module', component_module_namespace + '/' + component_module_name
  end

  context 'Get component module components list' do
    include_context 'Get component module components list', dtk_common, local_component_module_name
  end

  context 'Check if component module imported on local filesystem' do
    include_context 'Check component module imported on local filesystem', component_module_filesystem_location, component_module_name
  end

  context "Stage service on #{assembly_name} assembly" do
    include_context 'Stage', dtk_common
  end

  context 'List services after stage' do
    include_context 'List services after stage', dtk_common
  end

  context 'Set os attribute function' do
    include_context 'Set attribute', dtk_common, os_attribute, os
  end

  context 'Add components to service node' do
    include_context 'Add component to service node', dtk_common, node_name, component_module_name, component_module_namespace
  end

  context 'Converge function' do
    include_context 'Converge', dtk_common
  end

  context 'Delete and destroy service function' do
    include_context 'Delete services', dtk_common
  end

  context 'Delete component module' do
    include_context 'Delete component module', dtk_common, local_component_module_name
  end

  context 'Delete component module from local filesystem' do
    include_context 'Delete component module from local filesystem', component_module_filesystem_location, component_module_name
  end

  after(:all) do
    puts '', ''
  end
end
