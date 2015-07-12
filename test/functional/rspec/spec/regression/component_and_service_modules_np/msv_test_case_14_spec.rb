#!/usr/bin/env ruby
# Test Case 14: Import component module from r8 repo and export to default tenant namespace

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/parameters_setting_spec'
require './lib/component_modules_spec'

namespace = 'dtk17'
component_module_name = 'apache'
component_module_namespace = 'r8'
imported_component_module_name = 'r8:apache'
component_module_filesystem_location = '~/dtk/component_modules/r8'

dtk_common = Common.new('', '')

describe '(Modules, Services and Versioning) Test Case 14: Import component module from r8 repo and export to default tenant namespace' do
  before(:all) do
    puts '****************************************************************************************************************************', ''
  end

  context 'Import component module function' do
    include_context 'Import remote component module', component_module_namespace + '/' + component_module_name
  end

  context 'Get component module components list' do
    include_context 'Get component module components list', dtk_common, imported_component_module_name
  end

  context 'Check if component module imported on local filesystem' do
    include_context 'Check component module imported on local filesystem', component_module_filesystem_location, component_module_name
  end

  context 'Export component module to default namespace' do
    include_context 'Export component module', dtk_common, imported_component_module_name, namespace
  end

  context 'Delete component module' do
    include_context 'Delete component module', dtk_common, imported_component_module_name
  end

  context 'Delete component module from local filesystem' do
    include_context 'Delete component module from local filesystem', component_module_filesystem_location, component_module_name
  end

  context 'Delete component module from remote' do
    include_context 'Delete component module from remote repo', dtk_common, component_module_name, namespace
  end

  after(:all) do
    puts '', ''
  end
end
