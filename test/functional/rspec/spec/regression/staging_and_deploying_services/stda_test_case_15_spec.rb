#!/usr/bin/env ruby
# Test Case 15: Converge service instance with component that has delete action and delete/destroy service

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'

STDOUT.sync = true

namespace = 'dtk17'
service_module_name = 'test_delete'
component_module_name = 'test_delete'
service_name = 'stda_test_case_15_instance'
assembly_name = 'test_delete::delete_workflow'
components_to_delete = "test_delete::component"
check_component_in_task_status = true
dtk_common = Common.new(service_name, assembly_name)

describe '(Staging And Deploying Assemblies) Test Case 15: Converge service instance with component that has delete action and delete/destroy service' do
  before(:all) do
    puts '*******************************************************************************************************************************************', ''
  end

  context "Stage service function on #{assembly_name} assembly" do
    include_context 'Stage', dtk_common
  end

  context 'List services after stage' do
    include_context 'List services after stage', dtk_common
  end

  context 'Converge function' do
    include_context 'Converge', dtk_common
  end

  context 'Delete and destroy service with workflow' do
    include_context 'Delete service with workflow', dtk_common, components_to_delete, check_component_in_task_status
  end

  context 'List services after delete' do
    include_context 'List services after delete', dtk_common
  end

  after(:all) do
    puts '', ''
  end
end