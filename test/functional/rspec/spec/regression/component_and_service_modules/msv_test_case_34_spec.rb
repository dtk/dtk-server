#!/usr/bin/env ruby
# Test Case 34: Create test module in default namespace and in two different namespaces

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/test_modules_spec'

test_module = 'mytestmodule'
default_namespace = 'local'
new_namespace_1 = 'new_namespace_1'
new_namespace_2 = 'new_namespace_2'
default_filesystem_location = '~/dtk/test_modules'
new_component_module_filesystem_location_1 = '~/dtk/test_modules/new_namespace_1'
new_component_module_filesystem_location_2 = '~/dtk/test_modules/new_namespace_2'
local_component_module_filesystem_location = '~/dtk/test_modules/local'

dtk_common = DtkCommon.new('', '')

describe '(Modules, Services and Versioning) Test Case 34: Create test module in default namespace and in two different namespaces' do
  before(:all) do
    puts '************************************************************************************************************************', ''
  end

  context 'Create test module' do
    include_context 'Create test module', test_module
  end

  context 'Check if test module created on local filesystem' do
    include_context 'Check test module created on local filesystem', local_component_module_filesystem_location, test_module
  end

  context 'Create test module' do
    include_context 'Create test module', new_namespace_1 + ':' + test_module
  end

  context 'Check if test module created on local filesystem' do
    include_context 'Check test module created on local filesystem', new_component_module_filesystem_location_1, test_module
  end

  context 'Create test module' do
    include_context 'Create test module', new_namespace_2 + ':' + test_module
  end

  context 'Check if test module created on local filesystem' do
    include_context 'Check test module created on local filesystem', new_component_module_filesystem_location_2, test_module
  end

  context 'Delete test module' do
    include_context 'Delete test module', dtk_common, default_namespace + ':' + test_module
  end

  context 'Delete test module from local filesystem' do
    include_context 'Delete test module from local filesystem', local_component_module_filesystem_location, test_module
  end

  context 'Delete test module' do
    include_context 'Delete test module', dtk_common, new_namespace_1 + ':' + test_module
  end

  context 'Delete test module from local filesystem' do
    include_context 'Delete test module from local filesystem', new_component_module_filesystem_location_1, test_module
  end

  context 'Delete test module' do
    include_context 'Delete test module', dtk_common, new_namespace_2 + ':' + test_module
  end

  context 'Delete test module from local filesystem' do
    include_context 'Delete test module from local filesystem', new_component_module_filesystem_location_2, test_module
  end

  after(:all) do
    puts '', ''
  end
end
