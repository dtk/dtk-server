#!/usr/bin/env ruby
# Test Case 35: Install component module, publish to different namespace and install it again

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/component_modules_spec'

namespace = 'r8'
component_module_name = 'apache'
component_module = 'r8:apache'
new_component_module = 'dtk17:apache'
new_namespace = 'dtk17'
r8_component_module_filesystem_location = '~/dtk/component_modules/r8'
dtk17_component_module_filesystem_location = '~/dtk/component_modules/dtk17'

dtk_common = DtkCommon.new('', '')

describe '(Modules, Services and Versioning) Test Case 35: Install component module, publish to different namespace and install it again' do
  before(:all) do
    puts '******************************************************************************************************************************',''
  end

  context 'Import component module function' do
    include_context 'Import remote component module', namespace + '/' + component_module_name
  end

  context 'Get component module components list' do
    include_context 'Get component module components list', dtk_common, component_module
  end

  context 'Check if component module imported on local filesystem' do
    include_context 'Check component module imported on local filesystem', r8_component_module_filesystem_location, component_module_name
  end

  context 'Export component module to default namespace' do
    include_context 'Export component module', dtk_common, component_module, new_namespace
  end

  context 'Import previously exported component module' do
    include_context 'Import remote component module', new_namespace + '/' + component_module_name
  end

  context 'Get component module components list' do
    include_context 'Get component module components list', dtk_common, new_component_module
  end

  context 'Check if component module imported on local filesystem' do
    include_context 'Check component module imported on local filesystem', dtk17_component_module_filesystem_location, component_module_name
  end

  context 'Delete component module' do
    include_context 'Delete component module', dtk_common, component_module
  end

  context 'Delete component module from local filesystem' do
    include_context 'Delete component module from local filesystem', r8_component_module_filesystem_location, component_module_name
  end

  context 'Delete component module' do
    include_context 'Delete component module', dtk_common, new_component_module
  end

  context 'Delete component module from local filesystem' do
    include_context 'Delete component module from local filesystem', dtk17_component_module_filesystem_location, component_module_name
  end

  context 'Delete component module from remote' do
    include_context 'Delete component module from remote repo', dtk_common, component_module_name, new_namespace
  end

  after(:all) do
    puts '', ''
  end
end
