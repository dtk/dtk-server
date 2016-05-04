#!/usr/bin/env ruby
# Test Case 7: Create attribute on workspace (list attributes), set value for this attribute and then unset the value and purge workspace

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/workspace_spec'
require './lib/assembly_and_service_operations_spec'

STDOUT.sync = true

attribute_name = 'test'
attribute_value = '10'
workspace_instance_name = 'w_test_case_7_instance'

dtk_common = Common.new('', '')

describe '(Workspace) Test Case 7: Create attribute on workspace (list attributes), set value for this attribute and then unset the value and purge workspace' do
  before(:all) do
    puts '***************************************************************************************************************************************************', ''
  end

  context 'Create workspace' do
    include_context 'Create workspace instance', dtk_common, workspace_instance_name
  end

  context 'Create attribute in workspace' do
    include_context 'Create attribute in workspace', dtk_common, attribute_name
  end

  context 'Set attribute value in workspace' do
    include_context 'Set attribute value in workspace', dtk_common, attribute_name, attribute_value
  end

  context 'Delete workspace instance' do
    include_context 'Delete services', dtk_common
  end

  after(:all) do
    puts '', ''
  end
end
