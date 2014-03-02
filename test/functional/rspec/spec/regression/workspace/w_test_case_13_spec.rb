#!/usr/bin/env ruby
#Test Case 13: Create one node, add component in it, converge workspace and cancel tasks while converge is in execution

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/workspace_spec'

STDOUT.sync = true

node_name = 'test'
node_template = 'precise-micro'
component_name = 'stdlib'

dtk_common = DtkCommon.new('', '')

def converge_service_and_cancel_tasks(workspace_id)
	puts "Converge service and cancel tasks:", "----------------------------------"
	dtk_common = DtkCommon.new('', '')
	tasks_cancelled = false

	puts "Converge process for service with id #{workspace_id} started!"
	create_task_response = dtk_common.send_request('/rest/assembly/create_task', {:assembly_id => workspace_id})
	task_id = create_task_response['data']['task_id']
	puts "Task id: #{task_id}"
	task_execute_response = dtk_common.send_request('/rest/task/execute', {:task_id => task_id})

	sleep 20

	cancel_task_response = dtk_common.send_request('/rest/task/cancel_task', {:task_id => task_id})
	task_status_response = dtk_common.send_request('/rest/task/status', {:task_id=> task_id})

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
		puts "**********************************************************************************************************************************"
		puts "(Workspace) Test Case 13: Create one node, add component in it, converge workspace and cancel tasks while converge is in execution"
		puts "**********************************************************************************************************************************"
		puts ""
  	end

	context "Create node in workspace" do
		include_context "Create node in workspace", dtk_common, node_name, node_template
	end

	context "Add component to the node in workspace" do
		include_context "Add component to the node in workspace", dtk_common, node_name, component_name
	end		

	context "Converge and cancel workspace" do
		it "converges and then cancel workspace execution" do
			puts "Converge and cancel task in workspace", "-------------------------------------"
			workspace_id = dtk_common.get_workspace_id
			task_cancel = converge_assembly_and_cancel_tasks(workspace_id)
			puts ""
			task_cancel.should eq(true)
		end
	end

	context "Purge workspace content" do
		include_context "Purge workspace content", dtk_common
	end

	after(:all) do
		puts "", ""
	end
end