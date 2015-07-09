require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'

STDOUT.sync = true

class Tenant
  attr_accessor :ENDPOINT, :tenant, :error_message

  $opts = {
    timeout: 100,
    open_timeout: 50,
    cookies: {}
  }

  def initialize(server, port, username, password, tenant_number)
    @ENDPOINT = "http://#{server}:#{port}"
    @tenant = tenant_number

    # Login to dtk application
    response_login = RestClient.post(@ENDPOINT + '/rest/user/process_login', 'username' => username, 'password' => password, 'server_host' => server, 'server_port' => port)
    $opts[:cookies] = response_login.cookies
  end

  def send_request(path, body)
    resource = RestClient::Resource.new(@ENDPOINT + path, $opts)
    response = resource.post(body)
    response_JSON = JSON.parse(response)

    # If response contains errors, accumulate all errors to error_message
    unless response_JSON['errors'].nil?
      @error_message = ''
      response_JSON['errors'].each { |e| @error_message += "#{e['code']}: #{e['message']} " }
    end

    # If response status notok, show error_message
    if (response_JSON['status'] == 'notok')
      puts '', 'Request failed!'
      puts @error_message
      unless response_JSON['errors'].first['backtrace'].nil?
        puts '', 'Backtrace:'
        pretty_print_JSON(response_JSON['errors'].first['backtrace'])
      end
    end

    return response_JSON
  end

  def pretty_print_JSON(json_content)
    return ap json_content
  end

  def stage_assembly(assembly_template, assembly_name)
    # Get list of assembly templates, extract selected template, stage assembly and return its assembly id
    puts 'Stage assembly:', '---------------'
    assembly_id = nil
    extract_id_regex = /id: (\d+)/
    assembly_template_list = send_request('/rest/assembly/list', subtype: 'template')

    puts 'List of avaliable assembly templates: '
    pretty_print_JSON(assembly_template_list)

    test_template = assembly_template_list['data'].find { |x| x['display_name'] == assembly_template }

    if (!test_template.nil?)
      puts "Assembly template #{assembly_template} found!"
      template_assembly_id = test_template['id']
      puts "Assembly template id: #{template_assembly_id}"

      stage_assembly_response = send_request('/rest/assembly/stage', assembly_id: template_assembly_id, name: assembly_name)

      pretty_print_JSON(stage_assembly_response)

      if (stage_assembly_response['data'].include? "name: #{assembly_name}")
        puts "Stage of #{assembly_template} assembly template completed successfully!"
        assembly_id_match = stage_assembly_response['data'].match(extract_id_regex)
        assembly_id = assembly_id_match[1]
        puts "Assembly id for a staged assembly: #{assembly_id}"
      else
        puts 'Stage assembly didnt pass!'
      end
    else
      puts "Assembly template #{assembly_template} not found!"
    end
    puts ''
    return assembly_id.to_i
  end

  def add_component_to_assembly_node(assembly_id, node_name, component_name)
    puts 'Add component to assembly node:', '-------------------------------'
    component_added = false
    assembly_nodes = send_request('/rest/assembly/info_about', assembly_id: assembly_id, filter: nil, about: 'nodes', subtype: 'instance')

    if (assembly_nodes['data'].find { |x| x['display_name'] == node_name })
      puts "Node #{node_name} exists in assembly. Get node id..."
      node_id = assembly_nodes['data'].find { |x| x['display_name'] == node_name }['id']
      component_add_response = send_request('/rest/assembly/add_component', node_id: node_id, component_template_id: component_name, assembly_id: assembly_id)

      if (component_add_response['status'] == 'ok')
        puts "Component #{component_name} added to assembly!"
        component_added = true
      end
    end
    puts ''
    return component_added
  end

  def set_attribute(assembly_id, attribute_name, attribute_value)
    # Set attribute on particular assembly
    puts 'Set attribute:', '--------------'
    is_attributes_set = false

    # Get attribute id for which value will be set
    assembly_attributes = send_request('/rest/assembly/info_about', about: 'attributes', filter: nil, subtype: 'instance', assembly_id: assembly_id)
    pretty_print_JSON(assembly_attributes)
    attribute_id = assembly_attributes['data'].find { |x| x['display_name'].include? attribute_name }['id']

    # Set attribute value for given attribute id
    set_attribute_value_response = send_request('/rest/assembly/set_attributes', assembly_id: assembly_id, value: attribute_value, pattern: attribute_id)

    if (set_attribute_value_response['status'] == 'ok')
      puts "Setting of #{attribute_name} attribute completed successfully!"
      is_attributes_set = true
    end
    puts ''
    return is_attributes_set
  end

  def converge_assembly(assembly_id)
    puts 'Converge assembly:', '------------------'
    assembly_converged = false
    puts "Converge process for assembly with id #{assembly_id} started!"
    create_task_response = send_request('/rest/assembly/create_task', 'assembly_id' => assembly_id)

    if (create_task_response['status'].include? 'ok')
      task_id = create_task_response['data']['task_id']
      puts "Task id: #{task_id}"
      task_execute_response = send_request('/rest/task/execute', 'task_id' => task_id)
      end_loop = false
      count = 0
      max_num_of_retries = 30

      task_status = 'executing'
      while task_status.include? 'executing' || end_loop == false
        sleep 20
        count += 1
        response_task_status = send_request('/rest/task/status', { 'task_id' => task_id })
        status = response_task_status['data']['status']
        error_msg = response_task_status['data']['subtasks'].find { |x| x['type'].include? 'configure_nodes' }['subtasks']

        if (status.include? 'succeeded')
          task_status = status
          assembly_converged = true
          puts 'Converge process finished successfully!'
        end

        if (status.include? 'failed')
          task_status = status
          if (error_msg.to_s.include? 'timeout')
            assembly_converged = true
            puts 'Converge process finished successfully!'
          else
            puts 'Converge process was not finished successfully! Some tasks failed!'
            end_loop = true
          end
        end

        puts "Task execution status: #{task_status}"

        if (count > max_num_of_retries)
          puts 'Max number of retries reached...'
          puts 'Converge process was not finished successfully!'
          end_loop = true
        end
      end
    else
      puts 'Assembly was not converged successfully!'
    end

    puts ''
    return assembly_converged
  end
end

# Script execution part:
host = ARGV[0]
port = ARGV[1]
user = ARGV[2]
pass = ARGV[3]
tenant = ARGV[4]

# Initalize connection towards the server from which new tenant will be deployed
tenant_deploy = Tenant.new(host, port.to_i, user, pass, tenant)

# Stage tenant assembly
assembly_id = tenant_deploy.stage_assembly('dtk::tenant', "dtk#{tenant_deploy.tenant}tenant")

# Add needed component and set attributes
set_attributes_array = []
set_attributes_array << tenant_deploy.set_attribute(assembly_id, 'tenant/common_user/user', "git#{tenant_deploy.tenant}")
set_attributes_array << tenant_deploy.set_attribute(assembly_id, 'tenant/common_user::common_user_ssh_config/user', "dtk#{tenant_deploy.tenant}")
set_attributes_array << tenant_deploy.set_attribute(assembly_id, 'tenant/dtk_activemq/subcollective', "dtk#{tenant_deploy.tenant}")
set_attributes_array << tenant_deploy.set_attribute(assembly_id, 'tenant/dtk_activemq/user', "dtk#{tenant_deploy.tenant}")
set_attributes_array << tenant_deploy.set_attribute(assembly_id, 'tenant/dtk_postgresql::db/db_name', "dtk#{tenant_deploy.tenant}")
set_attributes_array << tenant_deploy.set_attribute(assembly_id, 'tenant/dtk_server::add_user/tenant_db_user', "dtk#{tenant_deploy.tenant}")
set_attributes_array << tenant_deploy.set_attribute(assembly_id, 'tenant/dtk_server::add_user/tenant_user', "dtk#{tenant_deploy.tenant}")
set_attributes_array << tenant_deploy.set_attribute(assembly_id, 'tenant/dtk_server::tenant/activemq_subcollective', "dtk#{tenant_deploy.tenant}")
set_attributes_array << tenant_deploy.set_attribute(assembly_id, 'tenant/dtk_server::tenant/activemq_user', "dtk#{tenant_deploy.tenant}")
set_attributes_array << tenant_deploy.set_attribute(assembly_id, 'tenant/dtk_server::tenant/gitolite_user', "git#{tenant_deploy.tenant}")
set_attributes_array << tenant_deploy.set_attribute(assembly_id, 'tenant/dtk_server::tenant/tenant_user', "dtk#{tenant_deploy.tenant}")
set_attributes_array << tenant_deploy.set_attribute(assembly_id, 'tenant/gitolite/gitolite_user', "git#{tenant_deploy.tenant}")
set_attributes_array << tenant_deploy.set_attribute(assembly_id, 'tenant/gitolite::admin_client/client_name', "dtk#{tenant_deploy.tenant}")
set_attributes_array << tenant_deploy.set_attribute(assembly_id, 'tenant/gitolite::admin_client/gitolite_user', "git#{tenant_deploy.tenant}")
set_attributes_array << tenant_deploy.set_attribute(assembly_id, 'tenant/thin/app_dir', "/home/dtk#{tenant_deploy.tenant}/server/application")
set_attributes_array << tenant_deploy.set_attribute(assembly_id, 'tenant/thin/daemon_user', "dtk#{tenant_deploy.tenant}")

# If all attribures have been set, proceed with tenant converge
if !set_attributes_array.include? false
  assembly_converged = tenant_deploy.converge_assembly(assembly_id)
  if assembly_converged == true
    puts 'Tenant assembly deployed!'
  else
    puts '[ERROR] Tenant assembly was not deployed successfully!'
  end
else
  puts '[ERROR] Some of the attributes are not set correctly. Will not proceed with converge process!'
end
