#!/usr/bin/env ruby
# Test Case 10: Stage assembly, check workflow info, list components with deps, push assembly updates, push component module updates

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/assembly_and_service_operations_spec'

STDOUT.sync = true

service_name = 'stda_test_case_10_instance'
assembly_name = 'mongodb_test::mongo_master_slave'
subtask_order = 'sequential'
subtasks = [{ 'node' => 'master', 'ordered_components' => ['mongodb', 'stdlib'] }, { 'node' => 'slave', 'ordered_components' => ['mongodb::mongodb_slave', 'stdlib'] }]
module_name = 'r8:mongodb'
service_module = 'r8:mongodb_test'
dependency_component = 'slave/mongodb::mongodb_slave'
dependency_name = 'master_conn'
dependency_satisfied_by = ['master/mongodb']
dtk_common = Common.new(service_name, assembly_name)

describe '(Staging And Deploying Assemblies) Test Case 10: Stage assembly, check workflow info, list components with deps, push assembly updates, push component module updates' do
  before(:all) do
    puts '*********************************************************************************************************************************************************************', ''
  end

  context "Stage service function on #{assembly_name} assembly" do
    include_context 'Stage', dtk_common
  end

  context 'List services after stage' do
    include_context 'List services after stage', dtk_common
  end

  context 'Check workflow info' do
    it 'checks that workflow info contains expected data' do
      workflow_verified = true
      workflow_content = dtk_common.get_workflow_info(dtk_common.service_id)

      ap workflow_content

      if workflow_content['subtask_order'] == subtask_order
        subtasks.each do |task|
          unless workflow_content['subtasks'].include? task
            workflow_verified = false
            break
          end
        end
      else
        workflow_verified = false
      end
      workflow_verified.should eq(true)
    end
  end

  context 'List component dependencies' do
    include_context 'List component dependencies', dtk_common, dependency_component, dependency_name, dependency_satisfied_by
  end

  context 'Push assembly updates' do
    include_context 'Push assembly updates', dtk_common, service_module
  end

  context 'Push component module updates' do
    include_context 'Push component module updates without changes', dtk_common, module_name, service_name
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
