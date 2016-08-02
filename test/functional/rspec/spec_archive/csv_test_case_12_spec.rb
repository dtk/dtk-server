#!/usr/bin/env ruby
# Test Case 12: NEG - Add component module to workspace and then create new version and try to add it to workspace too

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
version = '2.0.0'

dtk_common = Common.new('', '')

describe '(Component, service and versioning) Test Case 12: NEG - Add component module to workspace and then create new version and try to add it to workspace too' do
  before(:all) do
    puts '********************************************************************************************************************************************************', ''
  end

  context 'Create node in workspace' do
    include_context 'Create node in workspace', dtk_common, node_name, node_template
  end

  context 'Add component to the node in workspace' do
    include_context 'Add component to the node in workspace', dtk_common, node_name, component_name, component_module_namespace
  end

  context 'Create new component module version' do
    include_context 'Create component module version', dtk_common, imported_component_module_name, version
  end

  context 'NEG - Add versioned component to workspace' do
    include_context 'NEG - Add component to the node in workspace', dtk_common, node_name, component_name + "(#{version})", namespace
  end

  context 'Purge workspace content' do
    include_context 'Purge workspace content', dtk_common
  end

  context 'Delete component module version' do
    include_context 'Delete component module version', dtk_common, imported_component_module_name, version
  end

  after(:all) do
    puts '', ''
  end
end