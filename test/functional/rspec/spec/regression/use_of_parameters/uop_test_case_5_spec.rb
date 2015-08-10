#!/usr/bin/env ruby
# Test Case 5: Change optional params on existing attributes in service nodes (values were previously defined)

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/parameters_setting_spec'

service_name = 'uop_test_case_5_instance'
assembly_name = 'bootstrap::node_with_params'
os = 'precise'
instance_size = 't1.micro'
node_name = 'node1'
rhel_os = 'rhel6'
rhel_instance_size = 'm1.small'

dtk_common = Common.new(service_name, assembly_name)

describe '(Use Of Parameters) Test Case 5: Change optional params on existing attributes in service nodes (values were previously defined)' do
  before(:all) do
    puts '********************************************************************************************************************************', ''
  end

  context "Stage service function on #{assembly_name} assembly" do
    include_context 'Stage', dtk_common
  end

  context 'List services after stage' do
    include_context 'List services after stage', dtk_common
  end

  context 'Set os attribute function' do
    include_context 'Set attribute', dtk_common, 'os_identifier', os
  end

  context 'Set instance_size attribute function' do
    include_context 'Set attribute', dtk_common, 'instance_size', instance_size
  end

  context 'Converge function' do
    include_context 'Converge', dtk_common
  end

  context 'Check os attribute after converge' do
    include_context 'Check attribute', dtk_common, node_name, 'os_identifier', os
  end

  context 'Check instance_size attribute after converge' do
    include_context 'Check attribute', dtk_common, node_name, 'instance_size', instance_size
  end

  context "Set os attribute function with different value #{rhel_os}" do
    include_context 'Set attribute', dtk_common, 'os_identifier', rhel_os
  end

  context "Set instance_size attribute function with different value #{rhel_instance_size}" do
    include_context 'Set attribute', dtk_common, 'instance_size', rhel_instance_size
  end

  context 'Converge function again' do
    include_context 'Converge', dtk_common
  end

  context 'Check changed os attribute after converge' do
    include_context 'Check attribute', dtk_common, node_name, 'os_identifier', rhel_os
  end

  context 'Check changed instance_size attribute after converge' do
    include_context 'Check attribute', dtk_common, node_name, 'instance_size', rhel_instance_size
  end

  context 'Delete and destroy service function' do
    include_context 'Delete services', dtk_common
  end

  after(:all) do
    puts '', ''
  end
end
