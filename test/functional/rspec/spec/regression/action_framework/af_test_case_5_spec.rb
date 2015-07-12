#!/usr/bin/env ruby
# Test Case 5: Service with one node that contains cmp with actions (unless/if/file position)

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'

STDOUT.sync = true

service_name = 'af_test_case_5_instance'
service_module_namespace = 'test'
assembly_name = 'action_module::file-positioning-and-clauses'
dtk_common = Common.new(service_name, assembly_name)

expected_output_1 = {
  command: 'mkdir /tmp/test1 && rm -rf /tmp/test1',
  status: 0,
  stderr: nil
}

expected_output_2 = {
  command: 'mkdir /tmp/test2 && rm -rf /tmp/test2',
  status: 0,
  stderr: nil
}

expected_output_3_1 = {
  command: '/tmp/test.txt with provided content',
  status: 0,
  stderr: nil
}

expected_output_3_2 = {
  command: 'cat /tmp/test.txt | grep newtest',
  status: 0,
  stderr: nil
}

expected_output_3_3 = {
  command: 'rm -rf /tmp/test.txt',
  status: 0,
  stderr: nil
}

expected_output_4_1 = {
  command: '/tmp/test.txt with provided content',
  status: 0,
  stderr: nil
}

expected_output_4_2 = {
  command: 'rm -rf /tmp/test.txt',
  status: 0,
  stderr: nil
}

expected_output_5 = {
  command: '/tmp/test.txt with provided content',
  status: nil,
  stderr: "Permissions '0888' are not valid"
}

describe '(Action Framework) Test Case 5: Service with one node that contains cmp with actions (unless/if/file position)' do
  before(:all) do
    puts '**************************************************************************************************************', ''
  end

  context "Stage service function on #{assembly_name} assembly" do
    include_context 'Stage with namespace', dtk_common, service_module_namespace
  end

  context 'List services after stage' do
    include_context 'List services after stage', dtk_common
  end

  context 'NEG - Converge function' do
    include_context 'NEG - Converge', dtk_common
  end

  context 'Get task action details for action with successfull if command' do
    include_context 'Get task action details', dtk_common, '3.1', [expected_output_1]
  end

  context 'Get task action details for action with successfull unless command' do
    include_context 'Get task action details', dtk_common, '4.1', [expected_output_2]
  end

  context 'Get task action details for action with successfull create file command' do
    include_context 'Get task action details', dtk_common, '5.1', [expected_output_3_1, expected_output_3_2, expected_output_3_3]
  end

  context 'Get task action details for action with successfull create file with permissions command' do
    include_context 'Get task action details', dtk_common, '6.1', [expected_output_4_1, expected_output_4_2]
  end

  context 'Get task action details for action with failed create command (fake permissions)' do
    include_context 'Get task action details', dtk_common, '7.1', [expected_output_5]
  end

  context 'Delete and destroy service function' do
    include_context 'Delete services', dtk_common
  end

  context 'List services after delete' do
    include_context 'List services after delete', dtk_common
  end

  after(:all) do
    puts '', ''
  end
end
