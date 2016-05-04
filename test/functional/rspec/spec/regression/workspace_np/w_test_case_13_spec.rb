#!/usr/bin/env ruby
# Test Case 13: Create one node, add component in it, converge workspace and cancel tasks while converge is in execution

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/workspace_spec'
require './lib/assembly_and_service_operations_spec'

STDOUT.sync = true

node_name = 'test'
node_template = 'precise-micro'
component_name = 'stdlib'
component_module_namespace = 'r8'

dtk_common = Common.new('', '')

def converge_service_and_cancel_tasks(workspace_id)
	puts "Converge service and cancel tasks:", "----------------------------------"
	dtk_common = Common.new('', '')
	tasks_cancelled = false

	puts "Converge process for service with id #{workspace_id} started!"
	find_violations = dtk_common.send_request('/rest/assembly/find_violations', {'assembly_id' => workspace_id})
	create_task_response = dtk_common.send_request('/rest/assembly/create_task', {:assembly_id => workspace_id})
	task_id = create_task_response['data']['task_id']
	puts "Task id: #{task_id}"
	task_execute_response = dtk_common.send_request('/rest/task/execute', {:task_id => task_id})

	sleep 5

	cancel_task_response = dtk_common.send_request('/rest/task/cancel_task', {:task_id => task_id})
	task_status_response = dtk_common.send_request('/rest/assembly/task_status', {:assembly_id=> workspace_id})
	ap task_execute_response

	if task_status_response.to_s.include? 'cancelled'
		tasks_cancelled = true
		puts "Task execution status: cancelled"
		puts "Converge process has been cancelled successfully!"
	else task_status_response.to_s.include? 'failed'
		puts "Converge process has not been cancelled successfully!"
	end
	return tasks_cancelled
end

describe "(Workspace) Test Case 13: Create one node, add component in it, converge workspace and cancel tasks while converge is in execution" do

	before(:all) do
		puts "**********************************************************************************************************************************",""
  end

  context 'Create workspace' do
    include_context 'Create workspace instance', dtk_common, 'w_test_case_13_instance'
  end

	context "Create node in workspace" do
		include_context "Create node in workspace", dtk_common, node_name, node_template
	end

	context "Add component to the node in workspace" do
		include_context "Add component to the node in workspace", dtk_common, node_name, component_name, component_module_namespace
	end		

	context "Converge and cancel workspace" do
		it "converges and then cancel workspace execution" do
			puts "Converge and cancel task in workspace", "-------------------------------------"
			workspace_id = dtk_common.get_workspace_id
			task_cancel = converge_service_and_cancel_tasks(workspace_id)
			puts ""
			task_cancel.should eq(true)
		end
	end

	context 'Delete workspace instance' do
    include_context 'Delete services', dtk_common
  end

	after(:all) do
		puts "", ""
	end
end