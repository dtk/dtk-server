#!/usr/bin/env ruby
# Test Case 10: NEG - Have attribute with required field set to - falsee in dtk.model.yaml file and push-clone-changes to server

require 'rubygems'
require 'rest_client'
require 'pp'
require 'awesome_print'
require './lib/dtk_common'
require './lib/component_modules_spec'

component_module_name = 'temp'
component_module_namespace = 'dtk17'
local_component_module_name = 'dtk17:temp'
component_module_filesystem_location = '~/dtk/component_modules/dtk17'
file_for_change_location = './spec/regression/dslv3_component_modules_np/resources/cmd_test_case_10_dtk.model.yaml'
file_for_change = 'dtk.model.yaml'
fail_message = 'incorrect value for required field - falsee'
expected_error_message = 'ERROR'
dtk_common = DtkCommon.new('', '')

describe '(Component Module DSL) Test Case 10: NEG - Have attribute with required field set to - falsee in dtk.model.yaml file and push-clone-changes to server' do
  before(:all) do
    puts '*****************************************************************************************************************************************************', ''
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

  context 'Set required field to falsee in attribute section in dtk.model.yaml file' do
    include_context 'Replace dtk.model.yaml file with new one', component_module_name, file_for_change_location, file_for_change, component_module_filesystem_location, 'sets required field to incorrect value falsee in attribute members section in dtk.model.yaml'
  end

  context 'Push clone changes of component module from local copy to server' do
    include_context 'NEG - Push clone changes to server', local_component_module_name, fail_message, expected_error_message
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
