#!/usr/bin/env ruby

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require 'fileutils'

STDOUT.sync = true

SERVER = 'dev10.r8network.com'
ENDPOINT = "http://#{SERVER}"
ASSEMBLY_ID = '2147500839'
MEMORY_SIZE = 't1.micro'
OS_IDENTIFIERS = ['natty']#, 'oneiric', 'rh5.7-64']#ENV['operating_system']
LOG = '/home/dtk10/thin/log/thin.log'
COMPONENT = 'dtk_user::base'
# controling 'pretty-print' in log file
JSON_OUTPUT_ENABLED = false

$success = true

responseLogin = RestClient.post(ENDPOINT + '/rest/user/process_login', 'username' => 'dtk10', 'password' => 'r8server', 'server_host' => SERVER, 'server_port' => '7000')

@cookies = responseLogin.cookies

opts = {
                 timeout: 20,
            open_timeout: 5,
                 cookies: {}
}

opts[:cookies] = responseLogin.cookies

def send_request(path, body, opts)
  requestResponse = ::RestClient::Resource.new(ENDPOINT + path, opts).post(body)
  puts "Sending #{body.inspect} to " + ENDPOINT + path

  requestResponseJSON = JSON.parse(requestResponse)
  json_print requestResponseJSON

  unless requestResponseJSON['errors'].nil?
    error_message = ''
    requestResponseJSON['errors'].each { |e| error_message += "#{e['code']}: #{e['message']} "}
  end

  if requestResponseJSON['status'] == 'notok'
    $success = false
    puts '', 'Request failed.'
    puts error_message
    unless requestResponseJSON['errors'].first['backtrace'].nil?
      puts '', 'Backtrace:'
      ap requestResponseJSON['errors'].first['backtrace']
    end

    log_print()

  end

  return requestResponse
end

# Method for deleting assembly instances
def deleteAssembly(assemblyId, opts)
  responseAssemblyDelete = send_request('/rest/assembly/delete', {'assembly_id' => assemblyId}, opts)
  puts '', "Assembly has been deleted! Response: #{responseAssemblyDelete}"
end

#
# Method for pretty print of json responses
def json_print(json)
  ap json if JSON_OUTPUT_ENABLED
end

# Method that prints DTK server lines since the last restart
def log_print
  start_line = 1
  search_string = 'Exiting'

  # get lines of the file into an array (chomp optional)
  lines = File.readlines(LOG).map(&:chomp)

  #"cut" the deck, as with playing cards, so start_line is first in the array
  lines = lines.slice!(start_line..lines.length) + lines

  # searching backwards can just be searching a reversed array forwards
  lines.reverse!

  # search through the reversed-array, for the first occurence
  reverse_occurence = nil
  lines.each_with_index do |line,index|
    if line.include?(search_string)
      reverse_occurence = index
      break
    end
  end

  # reverse_occurence is now either "nil" for no match, or a reversed-index
  # also un-cut the array when calculating the index
  if reverse_occurence
      occurence = lines.size - reverse_occurence - 1 + start_line
      line = lines[reverse_occurence]
      puts '---------------------------------------------------------------------------------------------------------------'
      puts "Matched #{search_string} on line #{occurence}"
      puts line
      lines.reverse!
    puts 'Server log data since the last restart:'
    puts lines[occurence..(lines.size - 2)]
  end
end

def execute_task(taskId, opts)
  puts '', "Starting task id: #{taskId}"
  responseTaskExecute = send_request('/rest/task/execute', {'task_id' => taskId}, opts)

  taskStatus = 'executing'
  while taskStatus.include? 'executing'
    sleep 20
    responseTaskStatus = send_request('/rest/task/status', {'task_id'=> taskId}, opts)
    taskFullResponse = JSON.parse(responseTaskStatus)
    taskStatus = taskFullResponse['data']['status']
    puts "Task status: #{taskStatus}"
    json_print JSON.parse(responseTaskStatus)
  end

  if taskStatus.include? 'fail'
    $success = false
    # Print error response from the service
    puts '', 'Smoke test failed, response: '
    ap taskFullResponse
    puts 'Logs response:'
    task_log_response = send_request('/rest/task/get_logs', {'task_id '=> taskId}, opts)
    ap JSON.parse(task_log_response)

    log_print()

    return false
  else
    puts '', "Task with ID #{taskId} was successful!"
    return true
  end
end

def deploy_test_assembly(opts)

  OS_IDENTIFIERS.each do |os_identifier|
    puts '================================================================================='
    puts "Using OS Identifier: #{os_identifier}"
    puts "Using assembly template ID: #{ASSEMBLY_ID}"

    # listAssembly = send_request('/rest/assembly/list', {},  opts)

    # Stage the assembly
    stageAssembly = send_request('/rest/assembly/stage', {'assembly_id' => ASSEMBLY_ID}, opts)

    assemblyId = JSON.parse(stageAssembly)['data']['assembly_id']

    puts '', "Staged assembly ID: #{assemblyId}"

    attributes = JSON.parse(send_request('/rest/assembly/info_about', {subtype: 'instance', about: 'attributes', assembly_id: assemblyId, filter: nil}, opts))

    memory_size_id = attributes['data'].find{ |x| x['display_name'].include? 'memory_size' }['id']
    os_identifier_id = attributes['data'].find{ |x| x['display_name'].include? 'os_identifier' }['id']

    set_memory_attribute_response = send_request('/rest/assembly/set_attributes', {value: MEMORY_SIZE, pattern: memory_size_id, assembly_id: assemblyId}, opts)
    ap set_memory_attribute_response

    set_os_identifier_attribute_response = send_request('/rest/assembly/set_attributes', {value: os_identifier, pattern: os_identifier_id, assembly_id: assemblyId}, opts)
    ap set_os_identifier_attribute_response

    # Create a task for the cloned assembly instance
    responseTask = send_request('/rest/assembly/create_task', {'assembly_id' => assemblyId}, opts)

    # Extract task id
    taskId = JSON.parse(responseTask)['data']['task_id']
    # Execute the task
    puts '', "Starting task id: #{taskId}"
    responseTaskExecute = send_request('/rest/task/execute', {'task_id' => taskId}, opts)

    taskStatus = 'executing'
    while taskStatus.include? 'executing'
      sleep 20
      responseTaskStatus = send_request('/rest/task/status', {'task_id'=> taskId}, opts)
      taskFullResponse = JSON.parse(responseTaskStatus)
      taskStatus = taskFullResponse['data']['status']
      puts "Task status: #{taskStatus}"
      json_print JSON.parse(responseTaskStatus)
    end

    if taskStatus.include? 'fail'
      $success = false
      # Print error response from the service
      puts '', 'Smoke test failed, response: '
      ap taskFullResponse
      puts 'Logs response:'
      task_log_response = send_request('/rest/task/get_logs', {'task_id '=> taskId}, opts)
      ap JSON.parse(task_log_response)

      log_print()

      # Delete the cloned assembly's instance
      deleteAssembly(assemblyId)
      abort("Task with ID #{taskId} failed!")
    else
      puts '', "Task with ID #{taskId} was successful!"
    end

    # Test node group creation and reconverging
    # node_group_spin_up(opts)

    # Delete the cloned assembly's instance, this is the must!
    deleteAssembly(assemblyId, opts)

    # abort("Testing failure mail report.")
  end
end

def node_group_spin_up(opts)
  puts '', 'Starting node group test'
  # get the selected component ID
  componentListResponse = send_request('/rest/component/list', {}, opts)
  componentTemplateId = JSON.parse(componentListResponse)['data'].find{ |x| x['display_name'] == COMPONENT }['id']

  # create the node group
  nodeGroupResponse = send_request('/rest/node_group/create', {spans_target: true, display_name: 'all-nodes-jenkins-testing'}, opts)
  # ap JSON.parse(nodeGroupResponse)

  # add component to the node group
  addComponentResponse = send_request('/rest/node_group/add_component', {node_group_id: 'all-nodes-jenkins-testing', component_template_id: componentTemplateId}, opts)
  # ap JSON.parse(addComponentResponse)

  # converge the node group
  nodeConvergeResponse = send_request('/rest/node_group/create_task', {node_group_id: 'all-nodes-jenkins-testing'}, opts)
  # ap JSON.parse(nodeConvergeResponse)
  $success = execute_task(JSON.parse(nodeConvergeResponse)['data']['task_id'], opts)

  # delete node group
  nodeGroupDeleteResponse = send_request('/rest/node_group/delete', {node_group_id: 'all-nodes-jenkins-testing'} , opts)
end

def module_import(opts)
  puts '', 'Starting module import test'

  path_to_ssh_key = File.expand_path('~/.ssh/id_rsa.pub')
  user_ssh_key = File.open(path_to_ssh_key, 'rb') { |f| f.read.chomp }

  add_user_direct_access_response = send_request('/rest/component_module/add_user_direct_access', {rsa_pub_key: user_ssh_key}, opts)
  ap add_user_direct_access_response

  import_module_response = send_request('/rest/component_module/import', {remote_module_names: ['r8/test']}, opts)

  list_modules_response = send_request('/rest/component_module/list', {}, opts)
  $success = false unless list_modules_response.include? 'test'

  delete_module_response = send_request('/rest/component_module/delete', {component_module_id: 'test'}, opts)
  ap delete_module_response

  remove_user_direct_access_response = send_request('/rest/component_module/remove_user_direct_access', {rsa_pub_key: user_ssh_key}, opts)
  ap remove_user_direct_access_response

  list_modules_response = send_request('/rest/component_module/list', {}, opts)

  $success = false if JSON.parse(list_modules_response)['data'].select{ |x| x['display_name'] == 'test' } != []
  #$success = false if list_modules_response.include? 'test'
end

def stage_assembly(opts)
  stageAssembly = send_request('/rest/assembly/stage', {'assembly_id' => ASSEMBLY_ID}, opts)

  assemblyId = JSON.parse(stageAssembly)['data']['assembly_id']

  deleteAssembly(assemblyId, opts)
end

def module_create(opts)
  #   module_create_response = send_request('/rest/component_module/create_empty_repo', {:component_module_name=>"test_module"}, opts)
  #   repo_id = JSON.parse(module_create_response)["data"]["repo_id"]
  #   library_id = JSON.parse(module_create_response)["data"]["library_id"]
  #
  #   update_repo_response = send_request('/rest/component_module/update_repo_and_add_dsl', {:repo_id=>repo_id, :module_name=>"test_module", :library_id=>library_id, :scaffold_if_no_dsl=>true}, opts)
  #   ap update_repo_response
  puts '', 'Creating a new module from the local code...'
  ap `dtk module create "test_module"`

  puts '', 'Exporting the module to the remote repo...'
  module_export_response = send_request('/rest/component_module/export', {component_module_id: 'test_module'}, opts)

  puts '', 'Deleteing the local module...'
  module_delete_response = send_request('/rest/component_module/delete', {component_module_id: 'test_module'}, opts)
  ap module_delete_response

  puts '', 'Removing the module directory...'
  FileUtils.rm_rf(File.expand_path('~/component_modules/test_module'))

  puts '', 'Importing the module from the remote repo...'
  ap `dtk module import test_module`
  puts '', 'Cloning the imported module...'
  ap `echo "n\n" | dtk module clone test_module`

  puts '', 'Checking if the module is cloned/restored correctly...'
  if !File.exist?(File.expand_path('~/component_modules/test_module'))
    puts 'Test module not cloned correctly!'
    $success = false
  end

  puts '', 'Deleteing the local module...'
  module_delete_response = send_request('/rest/component_module/delete', {component_module_id: 'test_module'}, opts)
  ap module_delete_response

  puts '', 'Deleteing the remote module...'
  module_delete_remote_response = send_request('/rest/component_module/delete_remote', {remote_module_name: 'test_module'}, opts)
  ap module_delete_remote_response

  puts '', 'Make sure that the module is deleted.'
  list_modules_response = send_request('/rest/component_module/list', {}, opts)

  $success = false if JSON.parse(list_modules_response)['data'].select{ |x| x['display_name'] == 'test_module' } != []
end
##############################################################################################################################

puts '','Script has been started.'

deploy_test_assembly(opts)

# module_import(opts)

# module_create(opts)

# stage_assembly(opts)

abort('Job failed!') unless $success

#
# "http://ec2-184-72-164-154.compute-1.amazonaws.com:7000/rest/component_module/create_empty_repo"
# {:component_module_name=>"test_module"}
# "http://ec2-184-72-164-154.compute-1.amazonaws.com:7000/rest/component_module/update_repo_and_add_dsl"
# {:repo_id=>2147502620,
#  :module_name=>"test_module",
#  :library_id=>2147483655,
#  :scaffold_if_no_dsl=>true}
#
# "http://ec2-184-72-164-154.compute-1.amazonaws.com:7000/rest/component_module/export"
# {:component_module_id=>"test_module"}
#
# "http://ec2-184-72-164-154.compute-1.amazonaws.com:7000/rest/component_module/delete"
# {:component_module_id=>"test_module"}
#
# rm -rf ~/component_modules/test_module
#
# "http://ec2-184-72-164-154.compute-1.amazonaws.com:7000/rest/component_module/import"
# {:remote_module_names=>["test_module"]}
#
# "http://ec2-184-72-164-154.compute-1.amazonaws.com:7000/rest/component_module/create_workspace_branch"
# {"component_module_id"=>"2147502647"}
#
# ls ~/component_modules/test_module
#
# "http://ec2-184-72-164-154.compute-1.amazonaws.com:7000/rest/component_module/delete"
# {:component_module_id=>"test_module"}
#
# "http://ec2-184-72-164-154.compute-1.amazonaws.com:7000/rest/component_module/export"
# {:component_module_id=>"test_module"}
#
# "http://ec2-184-72-164-154.compute-1.amazonaws.com:7000/rest/component_module/delete_remote"
# {:remote_module_name=>"test_module"}
#
# =
