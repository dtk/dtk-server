#!/usr/bin/env ruby
# Test Case 1: Check possibility to create assembly from existing service and then to converge new assembly

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/parameters_setting_spec'

service_name = 'uop_test_case_1_instance'
assembly_name = 'bootstrap::node_with_params'
new_service_name = 'uop_test_case_1_instance2'
new_assembly = 'uop_test_case_1_temp'
service_module_name = 'bootstrap'
local_namespace = 'r8'

dtk_common = Common.new(service_name, assembly_name)
dtk_common2 = Common.new(new_service_name, "#{service_module_name}::#{new_assembly}")

describe '(Use Of Parameters) Test Case 1: Check possibility to create assembly from existing service and then to converge new assembly' do
  before(:all) do
    puts '*****************************************************************************************************************************', ''
  end

  context "Stage service function on #{assembly_name} assembly" do
    include_context 'Stage', dtk_common
  end

  context 'List services after stage' do
    include_context 'List services after stage', dtk_common
  end

  context 'Create new assembly from existing service' do
    include_context 'Create assembly from service', dtk_common, service_module_name, new_assembly, local_namespace
  end

  context 'Delete and destroy service function' do
    include_context 'Delete services', dtk_common
  end

  context "Stage new service function on #{assembly_name} assembly" do
    include_context 'Stage', dtk_common2
  end

  context 'List services after stage of new assembly' do
    include_context 'List services after stage', dtk_common2
  end

  context 'Converge function' do
    include_context 'Converge', dtk_common2
  end

  context 'Delete and destroy service function' do
    include_context 'Delete services', dtk_common2
  end

  context 'Delete assembly function' do
    include_context 'Delete assembly', dtk_common2, "#{service_module_name}/#{new_assembly}", local_namespace
  end

  after(:all) do
    puts '', ''
  end
end