#!/usr/bin/env ruby
# Test Case 11: Install component module and its version, check clone, delete and do clone again

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

namespace = 'version'
component_module_name = 'temp11'
component_module_namespace = 'version'
imported_component_module_name = 'version:temp11'
component_module_filesystem_location = '~/dtk/component_modules/version'
version = '0.0.1'

dtk_common = Common.new('', '')

describe '(Component, service and versioning) Test Case 11: Install component module and its version, check clone, delete and do clone again' do
  before(:all) do
    puts '*********************************************************************************************************************************', ''
  end

  context 'Install component module' do
    include_context 'Import remote component module', component_module_namespace + '/' + component_module_name
  end

  context 'Get component module components list' do
    include_context 'Get component module components list', dtk_common, imported_component_module_name
  end

  context 'Check if component module imported on local filesystem' do
    include_context 'Check component module imported on local filesystem', component_module_filesystem_location, component_module_name
  end

  context 'Install component module version' do
    include_context 'Install component module version', component_module_name, component_module_namespace, version
  end

  context 'Check if component module version imported on local filesystem' do
    include_context 'Check component module imported on local filesystem', component_module_filesystem_location, component_module_name + "-" + version
  end

  context 'Delete component module version from local filesystem' do
    include_context 'Delete component module from local filesystem', component_module_filesystem_location, component_module_name + "-" + version
  end

  context 'Clone component module version' do
    include_context 'Clone component module version', dtk_common, component_module_name, version
  end

  context 'Delete component module' do
    include_context 'Delete component module', dtk_common, imported_component_module_name
  end

  context 'Delete component module from local filesystem' do
    include_context 'Delete component module from local filesystem', component_module_filesystem_location, component_module_name
  end

  context 'Delete component module version' do
    include_context 'Delete component module version', dtk_common, component_module_name, version
  end

  context 'Delete component module version from local filesystem' do
    include_context 'Delete component module from local filesystem', component_module_filesystem_location, component_module_name + "-" + version
  end

  after(:all) do
    puts '', ''
  end
end