#!/usr/bin/env ruby
# Test Case 6: Service with five nodes that containt cmp with actions for tailing in nohup

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'

STDOUT.sync = true

service_name = 'af_test_case_6_instance'
service_module_namespace = 'r8'
assembly_name = 'action_module::nohup-log-tailing'
dtk_common = Common.new(service_name, assembly_name)

expected_output_1 = {
  command: 'nohup tail -f /var/log/dtk/dtk-arbiter.output',
  status: 0,
  stderr: nil
}

node_images=['precise','wheezy','trusty','amazon','rhel6']

describe '(Action Framework) Test Case 6: Service with five nodes that containt cmp with actions for tailing in nohup' do
  before(:all) do
	puts '************************************************************************************************************************', ''
  end

  context "Stage service function on #{assembly_name} assembly" do
    include_context 'Stage with namespace', dtk_common, service_module_namespace
  end

  context 'List services after stage' do
    include_context 'List services after stage', dtk_common
  end

  context 'Converge function' do
    include_context 'Converge', dtk_common
  end

  context "Get task action details for action executed on #{node_images[0]} node" do
    include_context 'Get task action details', dtk_common, '2.1', [expected_output_1]
  end

  context "Get task action details for action executed on #{node_images[1]} node" do
    include_context 'Get task action details', dtk_common, '2.2', [expected_output_1]
  end

  context "Get task action details for action executed on #{node_images[2]} node" do
    include_context 'Get task action details', dtk_common, '2.3', [expected_output_1]
  end

  context "Get task action details for action executed on #{node_images[3]} node" do
    include_context 'Get task action details', dtk_common, '2.4', [expected_output_1]
  end

  context "Get task action details for action executed on #{node_images[4]} node" do
    include_context 'Get task action details', dtk_common, '2.5', [expected_output_1]
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