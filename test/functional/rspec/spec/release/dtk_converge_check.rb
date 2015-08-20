#!/usr/bin/env ruby
require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require 'yaml'
require './lib/dtk_common'

STDOUT.sync = true

service_name = "test_service" + Random.rand(1000).to_s
assembly_name = ARGV[0]

def converge_and_check_logs(dtk_common, service_id)
  puts "Converge service:", "-----------------"
  nodes_created = false
  puts "Converge process for service with id #{service_id} started!"
  create_task_response = dtk_common.send_request('/rest/assembly/create_task', {'assembly_id' => service_id})

  if (dtk_common.error_message == "")
    task_id = create_task_response['data']['task_id']
    puts "Task id: #{task_id}"
    task_execute_response = dtk_common.send_request('/rest/task/execute', {'task_id' => task_id})
    end_loop = false
    count = 0
    task_status = 'executing'

    start_pattern_id = ""
    number_of_lines = 100

    while ((task_status.include? 'executing') && (end_loop == false))
      sleep 20
      count += 1
      response_task_status = dtk_common.send_request('/rest/assembly/task_status', {'assembly_id'=> service_id})
      status = response_task_status['data'].select { |x| x['type'].include? "create_nodes_stage" }.first['status']
      start_pattern_id = response_task_status['data'].select { |x| x["sub_index"] == 1 && (x["type"].include? "create_node") }.first['id']

      unless status.nil?
        if (status.include? 'succeeded')
          nodes_created = true
          puts "Nodes are created"
          end_loop = true
        elsif (status.include? 'failed')
          puts "Task execution status: #{status}"
          puts "Creating nodes failed!"
          end_loop = true
        end
        puts "Create nodes status: #{status}"
      end
    end
    log = dtk_common.get_server_log_for_specific_search_pattern("[\"start_action:\", \"CreateNode\", {:task_id=>#{start_pattern_id}}]", number_of_lines)
    log.each do |x|
      puts x
    end
  else
    puts "Service was not converged successfully!"
  end

  puts ""
  return nodes_created
end

dtk_common = Common.new(service_name, assembly_name)
dtk_common.stage_service
converge_and_check_logs(dtk_common, dtk_common.service_id)
dtk_common.delete_and_destroy_service(dtk_common.service_id)