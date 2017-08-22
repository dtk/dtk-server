#!/usr/bin/env ruby
# Test Case 10: Add versioned component module to workspace and converge

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/parameters_setting_spec'
require './lib/component_modules_spec'
require './lib/component_module_versions_spec'
require './lib/workspace_spec'

node_name = 'test'
node_template = 'precise-micro'
port_to_check = 22

namespace = 'version'
component_name = 'stdlib'
component_module_name = 'stdlib'
component_module_namespace = 'version'
imported_component_module_name = 'version:stdlib'
component_module_filesystem_location = '~/dtk/component_modules/version'
version = '0.0.1'
workspace_instance_name = 'csv_test_case_10_instance'
dtk_common = Common.new('', '')

describe '(Component, service and versioning) Test Case 10: Add versioned component module to workspace and converge' do
  before(:all) do
    puts '**********************************************************************************************************', ''
  end

  context 'Create workspace' do
    include_context 'Create workspace instance', dtk_common, workspace_instance_name
  end

  context 'Create node in workspace' do
    include_context 'Create node in workspace', dtk_common, node_name, node_template
  end

  context 'Add component to the node in workspace' do
    include_context 'Add component to the node in workspace', dtk_common, node_name, component_name + "(#{version})", component_module_namespace
  end

  context 'Converge workspace' do
    include_context 'Converge workspace', dtk_common
  end

  context "Check that port #{port_to_check}" do
    include_context 'Check if port avaliable', dtk_common, port_to_check
  end

  context 'Delete workspace instance' do
    include_context 'Delete services', dtk_common
  end

  after(:all) do
    puts '', ''
  end
end