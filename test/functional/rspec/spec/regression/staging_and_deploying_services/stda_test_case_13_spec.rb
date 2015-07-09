#!/usr/bin/env ruby
# Test Case 13: Ability to create assembly with components on assembly level and then converge it

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'
require './lib/parameters_setting_spec'
require './lib/node_operations_spec'

STDOUT.sync = true

service_name = 'stda_test_case_13_instance'
assembly_name = 'bootstrap::test1'
node_name = 'test1'
component_name = 'r8:stdlib'
components = ['stdlib']

new_service_name = 'stda_test_case_13_instance2'
new_assembly = 'stda_test_case_13_temp'
service_module_name = 'bootstrap'
local_namespace = 'r8'
port_to_check = 22

dtk_common = DtkCommon.new(service_name, assembly_name)
dtk_common2 = DtkCommon.new(new_service_name, "#{service_module_name}::#{new_assembly}")

describe '(Staging And Deploying Assemblies) Test Case 13: Ability to create assembly with components on assembly level and then converge it' do
  before(:all) do
    puts '**********************************************************************************************************************************', ''
  end

  context "Stage service function on #{assembly_name} assembly" do
    include_context 'Stage', dtk_common
  end

  context 'List services after stage' do
    include_context 'List services after stage', dtk_common
  end

  context 'Add components to service instance' do
    include_context 'Add specific component to service instance', dtk_common, component_name
  end

  context "List components on #{service_name} service" do
    include_context 'List components', dtk_common, components
  end

  context 'Create new assembly from existing service' do
    include_context 'Create assembly from service', dtk_common, service_module_name, new_assembly, local_namespace
  end

  context 'Delete and destroy service function' do
    include_context 'Delete services', dtk_common
  end

  context 'List services after delete' do
    include_context 'List services after delete', dtk_common
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

  context "Check that port #{port_to_check}" do
    include_context 'Check if port avaliable', dtk_common2, port_to_check
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
