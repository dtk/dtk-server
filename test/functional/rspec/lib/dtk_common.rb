#Common class with methods used for interaction with dtk server
require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require 'yaml'

STDOUT.sync = true

class DtkCommon

	attr_accessor :SERVER, :PORT, :ENDPOINT, :USERNAME, :PASSWORD
	attr_accessor :service_name, :service_id, :assembly, :node_id, :success, :error_message, :server_log
	attr_accessor :component_module_id_list

	$opts = {
		:timeout => 100,
		:open_timeout => 50,
		:cookies => {}
	}

	def initialize(service_name, assembly_name)
		config_yml = YAML::load(File.open("./config/config.yml"))		

		@service_name = service_name
		@assembly = assembly_name
		@SERVER = config_yml['r8server']['server']
		@PORT = config_yml['r8server']['port']
		@ENDPOINT = "#{@SERVER}:#{@PORT}"
		@USERNAME = config_yml['r8server']['username']
	  	@PASSWORD = config_yml['r8server']['password']
	  	@server_log = config_yml['r8server']['log']

		#used as placeholder for component ids for specific module that are accumulated
		@component_module_id_list = Array.new()

		#Login to dtk application
		response_login = RestClient.post(@ENDPOINT + '/rest/user/process_login', 'username' => @USERNAME, 'password' => @PASSWORD, 'server_host' => @SERVER, 'server_port' => @PORT)

		$cookies = response_login.cookies
		$opts[:cookies] = response_login.cookies
	end

	def server_log_print()
		search_string = "Exiting!"
		log_part_from_last_restart = []
		log_part = []
		final_log = []

		#read server log to an array
		server_log = File.readlines(@server_log)
		
		#reverse the array content and go through the log and break when first occurence of restarted server found!
		#write that part of the log to server_log array
		server_log.reverse!
		server_log.each do |line|
			log_part_from_last_restart << line
			if line.include? search_string
				break
			end
		end

		#search for the error that happened in log_part_from_last_restart array and print out next 20 lines in it
		log_part_from_last_restart.each_with_index do |line, index|
			if line.include? "error"
				for i in index-20..index
					log_part << log_part_from_last_restart[i]
				end
				break
			end
		end

		log_part.reverse!
            log_part.each do |line|
                if line.include? search_string
                    break
                else
                    final_log << line
                end
            end
		return final_log
	end

	def send_request(path, body)
		resource = RestClient::Resource.new(@ENDPOINT + path, $opts)
		response = resource.post(body)
		response_JSON = JSON.parse(response)

		#If response contains errors, accumulate all errors to error_message
		unless response_JSON["errors"].nil? 
			@error_message = ""
			response_JSON["errors"].each { |e| @error_message += "#{e['code']}: #{e['message']} "}
		end

		#If response status notok, show error_message
		if (response_JSON["status"] == "notok")
			puts "", "Request failed!"
			puts @error_message
			unless response_JSON["errors"].first["backtrace"].nil? 
				puts "", "Backtrace:"
				pretty_print_JSON(response_JSON["errors"].first["backtrace"])				
			end
			puts "", ""
			puts "Server log part:"
			puts "----------------"
			puts server_log_print()
			puts "----------------"
			puts "", ""
		else
			@error_message = ""
		end
		return response_JSON
	end

	def pretty_print_JSON(json_content)
		return ap json_content
	end

	def stage_service
		#Get list of assemblies, extract selected assembly, stage service and return its id
		puts "Stage service:", "--------------"
		service_id = nil
		extract_id_regex = /id: (\d+)/
		assembly_list = send_request('/rest/assembly/list', {:subtype=>'template'})
 
		puts "List of avaliable assemblies: "
		pretty_print_JSON(assembly_list)

		test_template = assembly_list['data'].select { |x| x['display_name'] == @assembly }.first

		if (!test_template.nil?)
			puts "Assembly #{@assembly} found!"
			assembly_id = test_template['id']
			puts "Assembly id: #{assembly_id}"

			stage_service_response = send_request('/rest/assembly/stage', {:assembly_id=>assembly_id, :name=>@service_name})	

			pretty_print_JSON(stage_service_response)

			if (stage_service_response['data'].include? "name: #{@service_name}")
				puts "Stage of #{@service_name} assembly completed successfully!"
				service_id_match = stage_service_response['data'].match(extract_id_regex)
				self.service_id = service_id_match[1].to_i
				puts "Service id for a staged service: #{self.service_id}"
			else
				puts "Stage service didnt pass!"
			end
		else
			puts "Assembly #{@service_name} not found!"
		end
		puts ""
	end

	def rename_service(service_id, new_service_name)
		puts "Rename service:", "---------------"
		service_renamed = false

		service_list = send_request('/rest/assembly/list', {:detail_level=>'nodes', :subtype=>'instance'})
		service_name = service_list['data'].select { |x| x['id'] == service_id }
		
		if service_name.any?
			puts "Old service name is: #{service_name}. Proceed with renaming it to #{new_service_name}..."
			rename_status = send_request('/rest/assembly/rename', {:assembly_id=>service_id, :assembly_name=>service_name, :new_assembly_name=>new_service_name})

			if rename_status['status'] == 'ok'
				puts "Service #{service_name} renamed to #{new_service_name} successfully!"
				service_renamed = true
			else
				puts "Service #{service_name} was not renamed to #{new_service_name} successfully!"
			end
		else
			puts "Service with id #{service_id} does not exist!"
		end
		puts ""
		return service_renamed
	end

	def check_if_service_exists(service_id)
		#Get list of existing services and check if staged service exists
		puts "Check if service exists:", "------------------------"
		service_exists = false
		service_list = send_request('/rest/assembly/list', {:detail_level=>'nodes', :subtype=>'instance'})
		puts "List of all services and its content:"
		pretty_print_JSON(service_list)
		test_service = service_list['data'].select { |x| x['id'] == service_id }

		puts "Service with id #{service_id}: "
		pretty_print_JSON(test_service)

		if (test_service.any?)	
			extract_service_id = test_service.first['id']
			execution_status = test_service.first['execution_status']

			if ((extract_service_id == service_id) && (execution_status == 'staged'))
				puts "Service with id #{service_id} exists!"
				service_exists = true
			end
		else
			puts "Service with id #{service_id} does not exist!"
		end
		puts ""
		return service_exists
	end

	def check_service_status(service_id, status_to_check)
		#Get list of services and check if service exists and its status
		puts "Check service status:", "---------------------"
		service_exists = false
		end_loop = false
		count = 0
		max_num_of_retries = 50

		while (end_loop == false)
			sleep 5
			count += 1

			service_list = send_request('/rest/assembly/list', {:subtype=>'instance'})
			service = service_list['data'].select { |x| x['id'] == service_id }.first

			if (!service.nil?)
				test_service = send_request('/rest/assembly/info', {:assembly_id=>service_id,:subtype=>:instance})
				op_status = test_service['data']['op_status']
				extract_service_id = service['id']

				if ((extract_service_id == service_id) && (op_status == status_to_check))
					puts "Service with id #{extract_service_id} has current op status: #{status_to_check}"
					service_exists = true
					end_loop = true
				else
					puts "Service with id #{extract_service_id} still does not have current op status: #{status_to_check}"
				end		
			else
				puts "Service with id #{service_id} not found in list"
				end_loop = true		
			end
			
			if (count > max_num_of_retries)
				puts "Max number of retries reached..."
				end_loop = true 
			end				
		end
		puts ""
		return service_exists
	end

	def set_attribute(service_id, attribute_name, attribute_value)
		#Set attribute on particular service
		puts "Set attribute:", "--------------"
		is_attributes_set = false

		#Get attribute id for which value will be set
		puts "List of service attributes:"
		service_attributes = send_request('/rest/assembly/info_about', {:about=>'attributes', :filter=>nil, :subtype=>'instance', :assembly_id=>service_id})
		pretty_print_JSON(service_attributes)
		attribute_id = service_attributes['data'].select { |x| x['display_name'].include? attribute_name }.first['id']

		#Set attribute value for given attribute id
		set_attribute_value_response = send_request('/rest/assembly/set_attributes', {:assembly_id=>service_id, :value=>attribute_value, :pattern=>attribute_id})

		puts "List of service attributes after adding #{attribute_value} value for #{attribute_name} attribute name:"
		service_attributes = send_request('/rest/assembly/info_about', {:about=>'attributes', :filter=>nil, :subtype=>'instance', :assembly_id=>service_id})
		pretty_print_JSON(service_attributes)
		extract_attribute_value = attribute_id = service_attributes['data'].select { |x| x['display_name'].include? attribute_name }.first['value']

		if (extract_attribute_value == attribute_value)
			puts "Setting of #{attribute_name} attribute completed successfully!"
			is_attributes_set = true
		end
		puts ""
		return is_attributes_set
	end

	def get_attribute_value(service_id, node_name, component_name, attribute_name)
		puts "Get attribute value by name:", "----------------------------"
		puts "List of service attributes:"
		service_attributes = send_request('/rest/assembly/info_about', {:assembly_id=>service_id, :filter=>nil, :about=>'attributes', :subtype=>'instance'})
		pretty_print_JSON(service_attributes)

		attributes = service_attributes['data'].select { |x| x['display_name'] == "#{node_name}/#{component_name}/#{attribute_name}" }.first

		if (!attributes.nil?)
			attribute_value = service_attributes['data'].select { |x| x['display_name'] == "#{node_name}/#{component_name}/#{attribute_name}" }.first['value']
			puts "Attribute value is: #{attribute_value}"
		else
			puts "Some of the input parameters is incorrect or missing. Node name: #{node_name}, Component name: #{component_name}, Attribute name: #{attribute_name}"
		end
		puts ""
		return attribute_value
	end

	def check_attribute_presence_in_nodes(service_id, node_name, attribute_name_to_check, attribute_value_to_check)
		puts "Check attribute presence in nodes:", "----------------------------------"		
		attribute_check = false
		#Get attribute and check if attribute name and attribute value exists
		puts "List of service attributes:"
		service_attributes = send_request('/rest/assembly/info_about', {:assembly_id=>service_id, :filter=>nil, :about=>'attributes', :subtype=>'instance'})
		pretty_print_JSON(service_attributes)

		if (service_attributes['data'].select { |x| x['display_name'] == "#{node_name}/#{attribute_name_to_check}" }.first)		
			attribute_name = attribute_name_to_check
			attribute_value = service_attributes['data'].select { |x| x['value'] == attribute_value_to_check }.first

			if (!attribute_value.nil?)
				puts "Attribute #{attribute_name_to_check} with value #{attribute_value_to_check} exists!" 
				attribute_check = true
			else
				puts "For attribute #{attribute_name_to_check}, value #{attribute_value_to_check} does not exist!"
			end

			if (attribute_value_to_check == '')
				puts "Attribute #{attribute_name_to_check} exists!" 
				attribute_check = true
			end
		else
			puts "Some of the input parameters is incorrect or missing. Node name: #{node_name}, Attribute name: #{attribute_name_to_check}, Attribute value: #{attribute_value_to_check}"
		end
		puts ""
		return attribute_check
	end

	def check_attribute_presence_in_components(service_id, node_name, component_name, attribute_name_to_check, attribute_value_to_check)
		puts "Check attribute presence in components:", "---------------------------------------"
		attribute_check = false
		#Get attribute and check if attribute name and attribute value exists
		puts "List of service attributes:"
		service_attributes = send_request('/rest/assembly/info_about', {:assembly_id=>service_id, :filter=>nil, :about=>'attributes', :subtype=>'instance'})
		pretty_print_JSON(service_attributes)

		puts "#{node_name}/#{component_name}/#{attribute_name_to_check}" 

		if (service_attributes['data'].select { |x| x['display_name'] == "#{node_name}/#{component_name}/#{attribute_name_to_check}" }.first)		
			attribute_name = attribute_name_to_check
			attribute_value = service_attributes['data'].select { |x| x['value'] == attribute_value_to_check }.first

			if (!attribute_value.nil?)
				puts "Attribute #{attribute_name_to_check} with value #{attribute_value_to_check} exists!" 
				attribute_check = true
			else
				puts "Attribute #{attribute_name_to_check} with value #{attribute_value_to_check} does not exist!"
				attribute_check = false
			end

			if (attribute_value_to_check == '')
				puts "Attribute #{attribute_name_to_check} exists!" 
				attribute_check = true
			end
		else
			puts "Some of the input parameters is incorrect or missing. Node name: #{node_name}, Component name: #{component_name}, Attribute name: #{attribute_name_to_check}, Attribute value: #{attribute_value_to_check}"
		end
		puts ""
		return attribute_check
	end

	def check_params_presence_in_nodes(service_id, node_name, param_name_to_check, param_value_to_check)
		puts "Check params presence in nodes:", "-------------------------------"
		param_check = false
		puts "List of service nodes:"
		service_nodes = send_request('/rest/assembly/info_about', {:assembly_id=>service_id, :filter=>nil, :about=>'nodes', :subtype=>'instance'})
		pretty_print_JSON(service_nodes)
		node_content = service_nodes['data'].select { |x| x['display_name'] == node_name }.first

 		if (!node_content.nil?)
			parameter = node_content[param_name_to_check]

			if ((parameter.to_s.empty?) || (!parameter.to_s.include? param_value_to_check))
				param_check = false
				puts "Node param with name: #{param_name_to_check} and value: #{param_value_to_check} does not exist!"
			else
				param_check = true
				puts "Node param with name: #{param_name_to_check} and value: #{param_value_to_check} exists!"
			end
		else
			param_check = false
			puts "Node with name #{node_name} does not exist!"
		end
		puts ""
		return param_check
	end

	def check_component_depedency(service_id, source_component, dependency_component, dependency_satisfied_by)
		puts "Check component dependency:", "---------------------------"
		dependency_found = false

		puts "List service components with dependencies:"
		components_list = send_request('/rest/assembly/info_about', {:assembly_id=>service_id, :filter=>nil, :about=>'components', :subtype=>'instance', :detail_to_include => [:component_dependencies]})
		component = components_list['data'].select { |x| x['display_name'] == source_component}.first

		if (!component.nil?)
			puts "Component #{source_component} exists. Check its dependencies..."
			if (component['depends_on'] == dependency_component)
				dependency_satisfied_by.each do |dep|
					if component['satisfied_by'].include? dep
						dependency_found = true
					else
						dependency_found = false
						break
					end
				end

				if dependency_found == true
					puts "Component #{source_component} has expected dependency component #{dependency_component} which is satisfied by #{dependency_satisfied_by}"
				else
					puts "Component #{source_component} does not have expected dependency component #{dependency_component} which is satisfied by #{dependency_satisfied_by}"
				end
			else
				puts "Component #{source_component} does not have expected dependency component #{dependency_component}"
			end
		else
			puts "Component #{source_component} does not exist and therefore it does not have any dependencies"
		end

		puts ""
		return dependency_found
	end

	def converge_service(service_id, max_num_of_retries=10)
		puts "Converge service:", "-----------------"
		service_converged = false
		puts "Converge process for service with id #{service_id} started!"
		create_task_response = send_request('/rest/assembly/create_task', {'assembly_id' => service_id})

		if (@error_message == "")
			task_id = create_task_response['data']['task_id']
			puts "Task id: #{task_id}"
			task_execute_response = send_request('/rest/task/execute', {'task_id' => task_id})
			end_loop = false
			count = 0

			task_status = 'executing'
			while ((task_status.include? 'executing') && (end_loop == false))
				sleep 20
				count += 1
				response_task_status = send_request('/rest/task/status', {'task_id'=> task_id})
				status = response_task_status['data']['status']
				if (status.include? 'succeeded')
					task_status = status
					service_converged = true
					puts "Task execution status: #{task_status}"
					puts "Converge process finished successfully!"
				elsif (status.include? 'failed')
					task_status = status
					puts "Task execution status: #{task_status}"
					puts "Converge process was not finished successfully! Some tasks failed!"
					end_loop = true
				end
				puts "Task execution status: #{task_status}"

				if (count > max_num_of_retries)
					puts "Max number of retries reached..."
					puts "Converge process was not finished successfully!"
					end_loop = true 
				end
			end
		else
			puts "Service was not converged successfully!"
		end

		puts ""
		return service_converged
	end

	def stop_running_service(service_id)
		puts "Stop running service:", "---------------------"
		service_stopped = false
		stop_service_response = send_request('/rest/assembly/stop', {:assembly_id => service_id})

		if (stop_service_response['data']['status'] == "ok")
			puts "Service stopped successfully!"
			service_stopped = true
		else
			puts "Service was not stopped successfully!"
		end
		puts ""
		return service_stopped
	end

	def stop_running_node(service_id, node_name)
		puts "Stop running node:", "------------------"
		node_stopped = false

		node_list = send_request('/rest/assembly/info_about', {:assembly_id=>service_id, :subtype=>'instance', :about=>'nodes'})
		node_id = node_list['data'].select { |x| x['display_name'] == node_name }.first['id']
		stop_node_response = send_request('/rest/assembly/stop', {:assembly_id => service_id, :node_pattern => node_id})

		if (stop_node_response['data']['status'] == "ok")
			puts "Node #{node_name} stopped successfully!"
			node_stopped = true
		else
			puts "Node #{node_name} was not stopped successfully!"
		end
		puts ""
		return node_stopped
	end

	def start_running_service(service_id)
		puts "Start service:", "--------------"
		service_started = false
		response = send_request('/rest/assembly/start', {:assembly_id => service_id, :node_pattern=>nil})
		pretty_print_JSON(response)
		task_id = response['data']['task_id']
		response = send_request('/rest/task/execute', {:task_id=>task_id})

		if (response['status'] == 'ok')
			end_loop = false
			count = 0
			max_num_of_retries = 30

			while (end_loop == false)
				sleep 10
		    	count += 1
				response = send_request('/rest/assembly/info_about', {:assembly_id => service_id, :subtype => 'instance', :about => 'tasks'})
				puts "Start instance check:"
				status = response['data'].select { |x| x['status'] == 'executing'}.first
				pretty_print_JSON(status)

				if (count > max_num_of_retries)
					puts "Max number of retries for starting instance reached..."
					end_loop = true
				elsif (status.nil?)
					puts "Instance started!"
					service_started = true
					end_loop = true
				end				
			end
		else
			puts "Start instance is not completed successfully!"
		end
		puts ""
		return service_started
	end

	def start_running_node(service_id, node_name)
		puts "Start running node:", "-------------------"
		node_started = false

		node_list = send_request('/rest/assembly/info_about', {:assembly_id=>service_id, :subtype=>'instance', :about=>'nodes'})
		node_id = node_list['data'].select { |x| x['display_name'] == node_name }.first['id']
		response = send_request('/rest/assembly/start', {:assembly_id => service_id, :node_pattern=>node_id})
		task_id = response['data']['task_id']
		response = send_request('/rest/task/execute', {:task_id=>task_id})

		if (response['status'] == 'ok')
			end_loop = false
			count = 0
			max_num_of_retries = 30

			while (end_loop == false)
				sleep 10
		    	count += 1
				response = send_request('/rest/assembly/info_about', {:assembly_id => service_id, :subtype => 'instance', :about => 'tasks'})
				puts "Start instance check:"
				status = response['data'].select { |x| x['status'] == 'executing'}.first
				pretty_print_JSON(status)

				if (count > max_num_of_retries)
					puts "Max number of retries for starting node #{node_name} reached..."
					end_loop = true
				elsif (status.nil?)
					puts "Node #{node_name} started!"
					node_started = true
					end_loop = true
				end				
			end
		else
			puts "Start #{node_name} node is not completed successfully!"
		end
		puts ""
		return node_started
	end

	def grep_node(service_id, node_name, log_location, grep_pattern)
		puts "Grep node:","----------"
		grep_pattern_found = false

		end_loop = false
		count = 0
		max_num_of_retries = 20

		while (end_loop == false)
			sleep 10
		    count += 1

		    response = send_request('/rest/assembly/initiate_grep', {:assembly_id => service_id, :subtype=>'instance', :log_path=>log_location, :node_pattern=>node_name, :grep_pattern=>grep_pattern, :stop_on_first_match =>false})
			action_results_id = response['data']['action_results_id']

			if (count > max_num_of_retries)
				puts "Max number of retries for grep pattern on node #{node_name} is reached..."
				end_loop = true
			end

			5.downto(1) do |i|
				sleep 1
				response = send_request('/rest/assembly/get_action_results', {:return_only_if_complete=>true, :action_results_id=>action_results_id.to_i, :disable_post_processing => true})
				puts "Starting grep command:"
				pretty_print_JSON(response)

				if response['data']['is_complete'] == true
					puts "Grep processing completed!"

					if response['data']['results'].to_s.include? grep_pattern
						grep_pattern_found = true 
					end
					end_loop = true
					break
				end				
			end			
		end
		puts ""
		return grep_pattern_found
	end

	def delete_and_destroy_service(service_id)
		#Cleanup step - Delete and destroy service
		puts "Delete and destroy service:", "---------------------------"
		service_deleted = false
		delete_service_response = send_request('/rest/assembly/delete', {:assembly_id=>service_id})

		if (delete_service_response['status'] == "ok")
			puts "Service deleted successfully!"
			service_deleted = true
		else
			puts "Service was not deleted successfully!"
		end
		puts ""
		return service_deleted
	end

	def delete_assembly(assembly_name)
		#Cleanup step - Delete assembly
		puts "Delete assembly:", "----------------"
		assembly_deleted = false
		assembly_list = send_request('/rest/assembly/list', {:detail_level=>"nodes", :subtype=>"template"})
		if (assembly_list['data'].select { |x| x['display_name'] == assembly_name }.first)
			puts "Assembly exists in assembly list. Proceed with deleting assembly..."
			delete_assembly_response = send_request('/rest/assembly/delete', {:assembly_id=>assembly_name, :subtype=>:template})

			if (delete_assembly_response['status'] == "ok")
				puts "Assembly #{assembly_name} deleted successfully!"
				assembly_deleted = true
			else
				puts "Assembly #{assembly_name} was not deleted successfully!"
			end
		else
			puts "Assembly does not exist in assembly template list."
		end
		puts ""
		return assembly_deleted
	end

	def create_assembly_from_service(service_id, service_module_name, assembly_name)
		puts "Create assembly from service:", "-----------------------------"
		assembly_created = false	
		create_assembly_response = send_request('/rest/assembly/promote_to_template', {:service_module_name=>service_module_name, :assembly_id=>service_id, :assembly_template_name=>assembly_name})
		if (create_assembly_response['status'] == 'ok')
			puts "Assembly #{assembly_name} created in service module #{service_module_name}"
			assembly_created = true
		else
			puts "Assembly #{assembly_name} was not created in service module #{service_module_name}" 
		end
		puts ""
		return assembly_created
	end

	def execute_tests(service_id)
		puts "Execute tests:", "---------------"

 		get_ps_tries = 6
      	get_ps_sleep = 0.5
      	count = 0

		end_loop = false

		response = send_request('/rest/assembly/initiate_execute_tests', {:node_id=>nil, :assembly_id=>service_id})
		action_results_id = response['data']['action_results_id']

		until end_loop do
	        response = send_request('/rest/assembly/get_action_results', {:disable_post_processing=>false, :return_only_if_complete=>true, :action_results_id=>action_results_id, :sort_key=>"module_name"})
	        count += 1
	        ap response

	        if count > get_ps_tries or response['data']['is_complete']
	          end_loop = true
	        else
	          #last time in loop return whetever is teher
	          if count == get_ps_tries
	            ret_only_if_complete = false
	          end
	          sleep get_ps_sleep
	        end
      	end
	end

	#dtk = DtkCommon.new('','')
	#dtk.execute_tests(2147860632)

	def netstats_check(service_id, port)
		puts "Netstats check:", "---------------"
 		netstats_check = false

		end_loop = false
		count = 0
		max_num_of_retries = 15

		while (end_loop == false)
			sleep 10
			count += 1

			if (count > max_num_of_retries)
				puts "Max number of retries for getting netstats reached..."
				end_loop = true
			end

			response = send_request('/rest/assembly/initiate_get_netstats', {:node_id=>nil, :assembly_id=>service_id})
			action_results_id = response['data']['action_results_id']

			5.downto(1) do |i|
				sleep 1
				response = send_request('/rest/assembly/get_action_results', {:disable_post_processing=>false, :return_only_if_complete=>true, :action_results_id=>action_results_id, :sort_key=>"port"})
				puts "Netstats check:"
				pretty_print_JSON(response)

				if response['data']['is_complete']
					port_to_check = response['data']['results'].select { |x| x['port'] == port}.first

					if (!port_to_check.nil?)
						puts "Netstats check completed! Port #{port} available!"
						netstats_check = true
						end_loop = true
						break
					else					
						puts "Netstats check completed! Port #{port} is not available!"
						netstats_check = false
						break
					end
				end				
			end
		end
		puts ""
		return netstats_check
	end

	def import_remote_component_module(component_module_to_import)
		puts "Import remote component module:", "-------------------------------"
		component_module_imported = false
		component_modules_list = send_request('/rest/component_module/list', {})
		
		if (component_modules_list['data'].select { |x| x['display_name'] == component_module_to_import }.first)
			puts "Component module #{component_module_to_import} already exists in component module list."
			component_module_imported = false
		else
			puts "Component module not found in component module list. Checking if component module exist on remote repo..."
			remote_component_modules_list = send_request('/rest/component_module/list_remote', {})

			if (remote_component_modules_list['data'].select { |x| x['display_name'].include? component_module_to_import}.first)
				puts "Component module specified found in list of remote component modules. Try to import component module..."
				import_response = send_request('/rest/component_module/import', {:remote_module_name=>component_module_to_import, :local_module_name=>component_module_to_import})
				puts "Component module import response:"
				pretty_print_JSON(import_response)
				component_modules_list = send_request('/rest/component_module/list', {})
				puts "List of avaliable component modules:"
				pretty_print_JSON(component_modules_list)

				if (import_response['status'] == 'ok' && component_modules_list['data'].select { |x| x['display_name'] == component_module_to_import }.first)
					puts "Component module imported successfully from remote repo."
					component_module_imported = true
				else
					puts "Component module was not imported from remote repo successfully."
					component_module_imported = false
				end
			else
				puts "Componetn module specified was not found in list of remote component modules."				
				component_module_imported = false
			end
		end
		puts ""
		return component_module_imported
	end

	def check_if_component_module_exists(component_module_name)
		puts "Check if component module exists:", "---------------------------------"
		component_module_exists = false
		component_modules_list = send_request('/rest/component_module/list', {})

		if (modules_list['data'].select { |x| x['display_name'] == component_module_name }.first)
			puts "Component module #{component_module_name} exists in module list."
			component_module_exists = true
		else
			puts "Component module #{component_module_name} does not exist in module list"
		end
		puts ""
		return component_module_exists
	end

	def export_component_module_to_remote(component_module_to_export, namespace)
		puts "Export component module to remote:", "----------------------------------"
		component_module_exported = false
		component_modules_list = send_request('/rest/component_module/list', {})

		if (component_modules_list['data'].select { |x| x['display_name'] == component_module_to_export }.first)
			puts "Component module #{component_module_to_export} exists in component module list. Check if component module exists on remote repo already..."
			remote_component_modules_list = send_request('/rest/component_module/list_remote', {})
			pretty_print_JSON(remote_component_modules_list)

			if (remote_component_modules_list['data'].select { |x| x['display_name'].include? "#{namespace}/#{component_module_to_export}"}.first)
   			puts "Component module #{component_module_to_export} was found in list of remote component modules."
   			component_module_exported = false
			else
				puts "Component module #{component_module_to_export} was not found in list of remote component modules. Proceed with export of component module..."
				component_module_id = component_modules_list['data'].select { |x| x['display_name'] == component_module_to_export}.first['id']

				export_response = send_request('/rest/component_module/export', {:remote_component_name=>"#{namespace}/#{component_module_to_export}", :component_module_id=>component_module_id})

				puts "Componetn module export response:"
				pretty_print_JSON(export_response)
				remote_component_modules_list = send_request('/rest/component_module/list_remote', {})

				if (remote_component_modules_list['data'].select { |x| x['display_name'].include? component_module_to_export}.first)
					puts "Component module #{component_module_to_export} exported successfully in namespace #{namespace}"
					component_module_exported = true
				else
					puts "Component module #{component_module_to_export} was not exported successfully in namespace #{namespace}"
					component_module_exported = false
				end			
			end
		else
			puts "Component module #{componet_module_to_export} not found in component module list and therefore cannot be exported"
			component_module_exported = false
		end
		puts ""
		return component_module_exported
	end

	def delete_component_module_from_remote(component_module_name, namespace)
		puts "Delete component module from remote:", "------------------------------------"
		component_module_deleted = false

		remote_component_modules_list = send_request('/rest/component_module/list_remote', {})
		puts "List of remote component modules:"
		pretty_print_JSON(remote_component_modules_list)

		if (remote_component_modules_list['data'].select { |x| x['display_name'].include? "#{namespace}/#{component_module_name}" }.first)
			puts "Component module #{component_module_name} in #{namespace} namespace exists. Proceed with deleting this component module..."
			delete_remote_module = send_request('/rest/component_module/delete_remote', {:remote_module_name=>component_module_name, :remote_module_namespace=>namespace})
			if (delete_remote_module['status'] == 'ok')
				puts "Component module #{component_module_name} in #{namespace} deleted from remote!"
				component_module_deleted = true
			else
				puts "Component module #{component_module_name} in #{namespace} was not deleted from remote!"
				component_module_deleted = false				
			end
		else
			puts "Component module #{component_module_name} in #{namespace} namespace does not exist!"
			component_module_deleted = false
		end
		puts ""
		return component_module_deleted
	end

	def get_component_module_components_list(component_module_name, filter_version)
		puts "Get component module components list:", "-------------------------------------"
		component_ids_list = Array.new()
		component_modules_list = send_request('/rest/component_module/list', {})

		if (component_modules_list['data'].select { |x| x['display_name'] == component_module_name}.first)
			puts "Component module #{component_module_name} exists in the list. Get component module id..."
			component_module_id = component_modules_list['data'].select { |x| x['display_name'] == component_module_name}.first['id']
			module_components_list = send_request('/rest/component_module/info_about', {:about=>"components", :component_module_id=>component_module_id})
			puts "List of component module components:"
			pretty_print_JSON(module_components_list)

			module_components_list['data'].each do |x|
				if (filter_version != "")
					@component_module_id_list << x['id'] if x['version'] == filter_version
					puts "Component module component: #{x['display_name']}"
				else
					@component_module_id_list << x['id'] if x['version'] == nil
					puts "Component module component: #{x['display_name']}"
				end
			end
		end
		puts ""
	end

	def get_component_module_attributes_list(component_module_name, filter_component)
		#Filter component used on client side after retrieving all attributes from all components
		puts "Get module attributes list:", "---------------------------"
		attribute_list = Array.new()
		component_modules_list = send_request('/rest/component_module/list', {})

		if (component_modules_list['data'].select { |x| x['display_name'] == component_module_name}.first)
			puts "Component module #{component_module_name} exists in the list. Get component module id..."
			component_module_id = component_modules_list['data'].select { |x| x['display_name'] == component_module_name}.first['id']
			component_module_attributes_list = send_request('/rest/component_module/info_about', {:about=>"attributes", :component_module_id=>component_module_id})
			puts "List of component module attributes:"
			pretty_print_JSON(component_module_attributes_list)

			component_module_attributes_list['data'].each do |x|
				if (filter_component != "")
					attribute_list << x['display_name'] if x['display_name'].include? filter_component
					puts "Component module attribute: #{x['display_name']}"
				else
					attribute_list << x['display_name']
					puts "Component module attribute: #{x['display_name']}"
				end
			end
		end
		puts ""
		return attribute_list
	end

	def get_component_module_attributes_list_by_component(component_module_name, component_name)
		#Filter by component name used on server side to retrieve only attributes for specific component in component module
		puts "Get component module attributes list by component:", "--------------------------------------------------"
		attribute_list = Array.new()
		component_modules_list = send_request('/rest/component_module/list', {})

		if (component_modules_list['data'].select { |x| x['display_name'] == component_module_name}.first)
			puts "Component module #{component_module_name} exists in the list. Get component module id..."
			component_module_id = component_modules_list['data'].select { |x| x['display_name'] == component_module_name}.first['id']
			module_components_list = send_request('/rest/component_module/info_about', {:about=>"components", :component_module_id=>component_module_id})
			puts "List of component module components:"
			pretty_print_JSON(module_components_list)

			if (module_components_list['data'].select { |x| x['display_name'] == component_name}.first)
				puts "Component #{component_name} exists in the list. Get component id..."
				component_id = module_components_list['data'].select { |x| x['display_name'] == component_name}.first['id']
				component_attributes_list = send_request('/rest/component_module/info_about', {:about=>"attributes", :component_module_id=>component_module_id, :component_template_id=>component_id})
				puts "List of component attributes:"
				pretty_print_JSON(component_attributes_list)

				component_attributes_list['data'].each do |x|
					attribute_list << x['display_name']
					puts "component attribute: #{x['display_name']}"
				end
			end
		end
		puts ""
		return attribute_list
	end

	def get_attribute_value_from_component_module(component_module_name, component_name, attribute_name)
		puts "Get attribute value from component module:", "------------------------------------------"
		component_modules_list = send_request('/rest/component_module/list', {})

		if (component_modules_list['data'].select { |x| x['display_name'] == component_module_name}.first)
			puts "Component module #{component_module_name} exists in the list. Get component module id..."
			component_module_id = component_modules_list['data'].select { |x| x['display_name'] == component_module_name}.first['id']
			component_module_attribute_list = send_request('/rest/component_module/info_about', {:about=>"attributes", :component_module_id=>component_module_id})
			pretty_print_JSON(component_module_attribute_list)
			attribute_value = component_module_attribute_list['data'].select { |x| x['display_name'] == "cmp[#{component_module_name}::#{component_name}]/#{attribute_name}" }.first['value']
			puts attribute_value
		end
		
		puts ""
		return attribute_value
	end

	def check_if_component_exists_in_component_module(component_module_name, filter_version, component_name)
		puts "Check if component exists in component module:", "----------------------------------------------"
		component_exists_in_component_module = false
		component_names_list = Array.new()
		component_modules_list = send_request('/rest/component_module/list', {})

		if (component_modules_list['data'].select { |x| x['display_name'] == component_module_name}.first)
			puts "Component module #{component_module_name} exists in the list. Get component module id..."
			component_module_id = component_modules_list['data'].select { |x| x['display_name'] == component_module_name}.first['id']
			module_components_list = send_request('/rest/component_module/info_about', {:about=>"components", :component_module_id=>component_module_id})
			puts "List of component module components:"
			pretty_print_JSON(module_components_list)

			module_components_list['data'].each do |x|
				if (filter_version != "")
					component_names_list << x['display_name'] if x['version'] == filter_version
					puts "module component: #{x['display_name']}"
				else
					component_names_list << x['display_name']
					puts "module component: #{x['display_name']}"
				end
			end
		end

		if component_names_list.include? component_name
			puts "Component names list includes #{component_name}"
			component_exists_in_component_module = true
		else
			puts "Component names list does not include #{component_name}"
		end
		puts ""
		return component_exists_in_component_module
	end

	def add_component_by_name_to_service_node(service_id, node_name, component_name)
		puts "Add component to service node:", "------------------------------"
		component_added = false
		service_nodes = send_request('/rest/assembly/info_about', {:assembly_id=>service_id, :filter=>nil, :about=>'nodes', :subtype=>'instance'})

		if (service_nodes['data'].select { |x| x['display_name'] == node_name }.first)
			puts "Node #{node_name} exists in service. Get node id..."
			node_id = service_nodes['data'].select { |x| x['display_name'] == node_name }.first['id']
			component_add_response = send_request('/rest/assembly/add_component', {:node_id=>node_id, :component_template_id=>component_name, :assembly_id=>service_id})

			if (component_add_response['status'] == 'ok')
				puts "Component #{component_name} added to service!"
				component_added = true
			end
		end
		puts ""
		return component_added
	end

	def delete_component_module(component_module_to_delete)
		puts "Delete component module:", "------------------------"
		component_module_deleted = false
		component_modules_list = send_request('/rest/component_module/list', {})

		if (component_modules_list['data'].select { |x| x['display_name'] == component_module_to_delete }.first)
			puts "Component module #{component_module_to_delete} exists in component module list. Try to delete component module..."
			delete_response = send_request('/rest/component_module/delete', {:component_module_id=>component_module_to_delete})
			puts "Component module delete response:"
			pretty_print_JSON(delete_response)

			if (delete_response['status'] == 'ok' && component_modules_list['data'].select { |x| x['module_name'] == nil })
				puts "Component module #{component_module_to_delete} deleted successfully"
				component_module_deleted = true
			else
				puts "Component module #{component_module_to_delete} was not deleted successfully"
				component_module_deleted = false
			end
		else
			puts "Component module #{component_module_to_delete} does not exist in component module list and therefore cannot be deleted."
			component_module_deleted = false
		end
		puts ""
		return component_module_deleted
	end

	def create_new_component_module_version(component_module_name, version)
		puts "Create new component module version:", "------------------------------------"
		component_module_versioned = false
		component_modules_list = send_request('/rest/component_module/list', {})

		if (component_modules_list['data'].select { |x| x['display_name'] == component_module_name }.first)
			puts "Component module #{component_module_name} exists in component module list. Try to version component module..."
			component_module_id = component_modules_list['data'].select { |x| x['display_name'] == component_module_name }.first['id']
			versioning_response = send_request('/rest/component_module/create_new_version', {:version=>version, :component_module_id=>component_module_id})
			puts "Versioning response:"
			pretty_print_JSON(versioning_response)
			puts "Component module list response:"
			component_modules_list = send_request('/rest/component_module/list', {:detail_to_include=>["versions"]})
			pretty_print_JSON(component_modules_list)

			if (versioning_response['status'] == 'ok' && component_modules_list['data'].select { |x| (x['display_name'] == component_module_name) && (x['versions'].include? version) }.first)
				puts "Component module #{component_module_name} versioned successfully."
				component_module_versioned = true
			else
				puts "Component module #{component_module_name} was not versioned successfully."
				component_module_versioned = false
			end
		else
			puts "Component module #{component_module_name} does not exist in component module list and therefore cannot be versioned."
			component_module_versioned = false
		end
		puts ""
		return component_module_versioned
	end

	def import_versioned_component_module_from_remote(component_module_name, version)
		puts "Import versioned component module from remote:", "----------------------------------------------"
		component_module_imported = false
		component_modules_list = send_request('/rest/component_module/list', {})

		if (component_modules_list['data'].select { |x| x['display_name'] == component_module_name }.first)
			puts "Component module #{component_module_name} exists in component module list. Try to import versioned component module..."
			component_module_id = component_modules_list['data'].select { |x| x['display_name'] == component_module_name }.first['id']
			import_response = send_request('/rest/component_module/import_version', {:version=>version, :component_module_id=>component_module_id})
			puts "Import versioned component module response:"
			pretty_print_JSON(import_response)
			puts "Component module list response:"
			component_modules_list = send_request('/rest/component_module/list', {:detail_to_include=>["versions"]})
			pretty_print_JSON(component_modules_list)

			if (import_response['status'] == 'ok' && component_modules_list['data'].select { |x| (x['display_name'] == component_module_name) && (x['versions'].include? version) }.first)
				puts "Versioned component module imported successfully."
				component_module_imported = true
			else
				puts "Versioned component module was not imported successfully."
				component_module_imported = false
			end
		else
			puts "Component module #{component_module_name} does not exist in component module list and therefore versioned component module cannot be imported."
			component_module_imported = false
		end
		puts ""
		return component_module_imported
	end

	def import_new_service_module(service_module_name)
		puts "Import new service module:", "--------------------------"
		service_module_created = false
		service_module_list = send_request('/rest/service_module/list', {})

		if (service_module_list['data'].select { |x| x['display_name'] == service_module_name }.first)
			puts "Service module already exists with name #{service_module_name}."
		else
			puts "Service module does not exist. Try to create service module with name #{service_module_name}..."
			import_service_module_response = send_request('/rest/service_module/create', {:module_name=>service_module_name})
			puts "Service module import response:"
			pretty_print_JSON(import_service_module_response)

			service_module_list = send_request('/rest/service_module/list', {})
			puts "Service list response:"
			pretty_print_JSON(service_module_list)

			if (service_module_list['data'].select { |x| x['display_name'] == service_module_name }.first)
				puts "New service module #{service_module_name} has been added successfully."
				service_module_created = true
			else
				puts "New service module #{service_module_name} was not added successfully."
			end
		end
		puts ""
		return service_module_created
	end

	def check_if_service_module_exists(service_module_name)
		puts "Check if service module exists:", "-------------------------------"
		service_module_exists = false
		service_module_list = send_request('/rest/service_module/list', {})

		if (service_module_list['data'].select { |x| x['display_name'] == service_module_name }.first)
			puts "Service #{service_module_name} exists."
			service_module_exists = true
		else
			puts "Service #{service_module_name} does not exist!"
		end
		puts ""
		return service_module_exists
	end

	def check_if_service_module_exists_on_remote(service_module_name, namespace)
		puts "Check if service module exists on remote:", "-----------------------------------------"
		service_module_exists = false
		service_remote_list = send_request('/rest/service_module/list_remote', {})
		puts "Service module list on remote:"
		pretty_print_JSON(service_remote_list)

		if (service_remote_list['data'].select { |x| x['display_name'] == "#{namespace}/#{service_module_name}" }.first)
			puts "Service module #{service_module_name} with namespace #{namespace} exists on remote repo!"
			service_module_exists = true
		else
			puts "Service module #{service_module_name} with namespace #{namespace} does not exist on remote repo!"
		end
		puts ""
		return service_module_exists
	end

	def export_service_module_to_remote(service_module_name, namespace)
		puts "Export service module to remote:", "--------------------------------"
		service_module_exported = false
		service_module_list = send_request('/rest/service_module/list', {})

		if (service_module_list['data'].select { |x| x['display_name'] == service_module_name }.first)
			puts "Service module #{service_module_name} exists in service module list. Check if service module exists on remote repo already..."
			service_remote_list = send_request('/rest/service_module_name_name/list_remote', {})

			if (service_remote_list['data'].select { |x| x['display_name'].include? service_module_name }.first)
   			puts "Service module #{service_module_name} was found in list of remote service modules."
   			service_module_name_name_exported = false
			else
				puts "Service module #{service_module_name} was not found in list of remote service modules. Proceed with export of service module..."
				service_module_id = service_module_list['data'].select { |x| x['display_name'] == service_module_name}.first['id']				
				export_response = send_request('/rest/service_module/export', {:remote_component_name=>"#{namespace}/#{service_module_name}", :service_module_id=>service_module_id})

				puts "Service module export response:"
				pretty_print_JSON(export_response)
				service_module_remote_list = send_request('/rest/service_module/list_remote', {})

				if (service_module_remote_list['data'].select { |x| x['display_name'].include? service_module_name}.first)
					puts "Service module #{service_module_name} exported successfully in namespace #{namespace}"
					service_module_exported = true
				else
					puts "Service module #{service_module_name} was not exported successfully in namespace #{namespace}"
					service_module_exported = false
				end			
			end
		else
			puts "Service module #{service_module_name} not found in service list and therefore cannot be exported"
			service_module_exported = false
		end
		puts ""
		return service_module_exported
	end

	def delete_service_module(service_module_name)
		puts "Delete service module:", "----------------------"
		service_module_deleted = false
		service_module_list = send_request('/rest/service_module/list', {})

		if (service_module_list['data'].select { |x| x['display_name'] == service_module_name }.first)
			puts "Service module exists in service module list. Try to delete service module #{service_module_name}..."
			delete_service_module_response = send_request('/rest/service_module/delete', {:service_module_id=>service_module_name})
			puts "Service module delete response:"
			pretty_print_JSON(delete_service_module_response)

			service_module_list = send_request('/rest/service_module/list', {})
			puts "Service module list response:"
			pretty_print_JSON(service_module_list)

			if (delete_service_module_response['status'] == 'ok' && !service_module_list['data'].select { |x| x['display_name'] == service_module_name }.first)
				puts "Service module #{service_name} deleted successfully."
				service_module_deleted = true
			else
				puts "Service module #{service_name} was not deleted successfully."
				service_module_deleted = false
			end			
		else
			puts "Service module #{service_name} does not exist in service module list and therefore cannot be deleted."
			service_module_deleted = false
		end
		puts ""
		return service_module_deleted
	end

	def delete_service_module_from_remote(service_module_name, namespace)
		puts "Delete service module from remote:", "----------------------------------"
		service_module_deleted = false

		service_module_remote_list = send_request('/rest/service_module/list_remote', {})
		puts "List of remote service module:"
		pretty_print_JSON(service_module_remote_list)

		if (service_module_remote_list['data'].select { |x| x['display_name'].include? "#{namespace}/#{service_module_name}" }.first)
			puts "Service module #{service_module_name} in #{namespace} namespace exists. Proceed with deleting this service module..."
			delete_remote_service_module = send_request('/rest/service_module/delete_remote', {:remote_service_name=>"#{namespace}/#{service_module_name}"})
			if (delete_remote_service_module['status'] == 'ok')
				puts "Service module #{service_module_name} in #{namespace} deleted from remote!"
				service_module_deleted = true
			else
				puts "Service module #{service_module_name} in #{namespace} was not deleted from remote!"
				service_module_deleted = false				
			end
		else
			puts "Service module #{service_module_name} in #{namespace} namespace does not exist on remote!"
			service_module_deleted = false
		end
		puts ""
		return service_module_deleted
	end

	def check_if_service_module_contains_assembly(service_module_name, assembly_name)
		puts "Check if service module contains assembly:", "------------------------------------------"
		service_module_contains_assembly = false
		service_module_list = send_request('/rest/service_module/list', {})

		if (service_module_list['data'].select { |x| x['display_name'] == service_module_name }.first)
			puts "Service module exists in service module list. Try to find if #{assembly_name} assembly belongs to #{service_module_name} service module..."
			service_module_id = service_module_list['data'].select { |x| x['display_name'] == service_module_name }.first['id']
			service_module_assembly_list = send_request('/rest/service_module/list_assemblies', {:service_module_id=>service_module_id})
			puts "List of assemblies that belong to service #{service_module_name}:"
			pretty_print_JSON(service_module_assembly_list)

			if (service_module_assembly_list['data'].select { |x| x['display_name'] == assembly_name }.first)
				puts "Assembly #{assembly_name} belongs to #{service_module_name} service."
				service_module_contains_assembly = true
			else
				puts "Assembly #{assembly_name} does not belong to #{service_module_name} service."
				service_module_contains_assembly = false
			end
		else
			puts "Service module #{service_module_name} does not exist in service module list."
			service_module_contains_assembly = false
		end
		puts ""
		return service_module_contains_assembly
	end

	def check_component_modules_in_service_module(service_module_name, components_list_to_check)
		puts "Check component modules in service module:", "------------------------------------------"
		all_components_exist_in_service_module = false
		components_exist = Array.new()
		service_module_list = send_request('/rest/service_module/list', {})

		if (service_module_list['data'].select { |x| x['display_name'] == service_module_name }.first)
			puts "Service module exists in service module list. Try to find all component modules that belong to #{service_module_name} service module..."
			service_module_id = service_module_list['data'].select { |x| x['display_name'] == service_module_name }.first['id']
			component_modules_list = send_request('/rest/service_module/list_component_modules', {:service_module_id => service_module_id})
			pretty_print_JSON(component_modules_list)

			components_list_to_check.each do |component|
				if (component_modules_list['data'].select {|x| x['display_name'] == component}.first)
					components_exist << true
				else
					components_exist << false
				end
			end

			if (!components_exist.include? false)
				all_components_exist_in_service_module = true
				puts "All components #{components_list_to_check.inspect} exist in #{service_module_name} service module"
			end
		else
			puts "Service module #{service_module_name} does not exist in service module list."
		end
		return all_components_exist_in_service_module
	end

	def stage_node_template(node_name, staged_node_name)
		#Get list of node templates, extract selected template, stage node template and return its node id
		puts "Stage node:", "-----------"
		node_id = nil
		node_template_list = send_request('/rest/node/list', {:subtype=>'template'})

		puts "List of avaliable node templates: "
		pretty_print_JSON(node_template_list)

		test_template = node_template_list['data'].select { |x| x['display_name'] == node_name }.first

		if (!test_template.nil?)
			puts "Node template #{node_name} found!"
			template_node_id = test_template['id']
			puts "Node template id: #{template_node_id}"
			stage_node_response = send_request('/rest/node/stage', {:node_template_identifier=>template_node_id, :name=>staged_node_name})		

			if (stage_node_response['data']['node_id'])
				puts "Stage of #{node_name} node template completed successfully!"
				self.node_id = stage_node_response['data']['node_id']
				puts "Node id for a staged node template: #{self.node_id}"
			else
				puts "Stage node didnt pass!"
			end
		else
			puts "Node template #{node_name} not found!"
		end
		puts ""
	end

	def check_if_node_exists(node_id)
		#Get list of existing nodes and check if staged node exists
		puts "Check if node exists:", "---------------------"
		node_exists = false
		node_list = send_request('/rest/node/list', nil)
		test_node = node_list['data'].select { |x| x['id'] == node_id }

		puts "Node with id #{node_id}: "
		pretty_print_JSON(test_node)

		if (test_node.any?)	
			extract_node_id = test_node.first['id']
			execution_status = test_node.first['type']

			if ((extract_node_id == node_id) && (execution_status == 'staged'))
				puts "Node with id #{node_id} exists!"
				node_exists = true
			end
		else
			puts "Node with id #{node_id} does not exist!"
		end
		puts ""
		return node_exists
	end

	def converge_node(node_id)
		puts "Converge node:", "--------------"
		node_converged = false
		puts "Converge process for node with id #{node_id} started!"
		create_task_response = send_request('/rest/node/create_task', {'node_id' => node_id})

		if (@error_message == "")
			task_id = create_task_response['data']['task_id']
			puts task_id
			task_execute_response = send_request('/rest/task/execute', {'task_id' => task_id})
			end_loop = false
			count = 0
			max_num_of_retries = 10

			task_status = 'executing'
			while task_status.include? 'executing' || end_loop == false
				sleep 30
				count += 1
				response_task_status = send_request('/rest/task/status', {'task_id'=> task_id})
				status = response_task_status['data']['status']
				if (status.include? 'succeeded')
					task_status = status
					node_converged = true
					puts "Converge process finished successfully!"
				elsif (status.include? 'failed')
					task_status = status
					puts "Converge process was not finished successfully! Some tasks failed!"
				end
				puts "Task execution status: #{task_status}"

				if (count > max_num_of_retries)
					puts "Max number of retries reached..."
					puts "Converge process was not finished successfully!"
					end_loop = true 
				end
			end
		else
			puts "Node was not converged successfully!"
		end
		puts ""
		return node_converged
	end

	def destroy_node(node_id)
		#Cleanup step - Destroy node
		puts "Destroy node:", "-------------"
		node_deleted = false
		delete_node_response = send_request('/rest/node/destroy_and_delete', {:node_id=>node_id})

		if (delete_node_response['status'] == "ok")
			puts "Node deleted successfully!"
			node_deleted = true
		else
			puts "Node was not deleted successfully!"
		end
		puts ""
		return node_deleted
	end

	def add_component_to_node(node_id, component_name)
		puts "Add component to node:", "----------------------"
		component_added = false

		components_list = send_request('/rest/component/list', {})
		pretty_print_JSON(components_list)

		component = components_list['data'].select { |x| x['display_name'] == component_name }.first
		puts component

		if (!component.nil?)
			puts "Component #{component_name} exists! Add this component to node #{node_id}..."
			component_add_response = send_request('/rest/node/add_component', {:node_id=>node_id, :component_template_name=>component['id']})

			if (component_add_response['status'] == 'ok')
				puts "Component #{component_name} added to node!"
				component_added = true
			end
		else
			puts "Component #{component_name} does not exist!"
		end
		puts ""
		return component_added
	end

	def set_attribute_on_node(node_id, attribute_name, attribute_value)
		#Set attribute on particular node
		puts "Set attribute on node:", "----------------------"
		is_attribute_set = false

		#Get attribute id for which value will be set
		puts "List of node attributes:"
		node_attributes = send_request('/rest/node/info_about', {:about=>'attributes', :subtype=>'instance', :node_id=>node_id})
		pretty_print_JSON(node_attributes)

		if (node_attributes['data'].select { |x| x['display_name'].include? attribute_name }.first)
			attribute_id = node_attributes['data'].select { |x| x['display_name'].include? attribute_name }.first['id']
			#Set attribute value for given attribute id
			select_attribute_value_response = send_request('/rest/node/set_attributes', {:node_id=>node_id, :value=>attribute_value, :pattern=>attribute_id})
			extract_attribute_value = select_attribute_value_response['data'].first['value']

			if (extract_attribute_value == attribute_value)
				puts "Setting of #{attribute_name} attribute completed successfully!"
				is_attribute_set = true
			end
		else
			puts "Attribute #{attribute_name} does not exist on node!"
		end
		puts ""
		return is_attribute_set
	end

	def check_get_netstats(node_id, port)
		puts "Netstats check:", "---------------"
		sleep 10 #Before initiating netstats check, wait for services to be up
 		netstats_check = false
		response = send_request('/rest/node/initiate_get_netstats', {:node_id=>node_id})
		action_results_id = response['data']['action_results_id']

		end_loop = false
		count = 0
		max_num_of_retries = 10

		while (end_loop == false)
			sleep 10
			count += 1
			response = send_request('/rest/node/get_action_results', {:disable_post_processing=>false, :return_only_if_complete=>true, :action_results_id=>action_results_id, :sort_key=>"port"})
			puts "Netstats check:"
			pretty_print_JSON(response)

			if (count > max_num_of_retries)
				puts "Max number of retries for getting netstats reached..."
				end_loop = true
			elsif (response['data']['is_complete'])
				port_to_check = response['data']['results'].select { |x| x['port'] == port}.first

				if (!port_to_check.nil?)
					puts "Netstats check completed! Port #{port} avaiable!"
					netstats_check = true
					end_loop = true
				else					
					puts "Netstats check completed! Port #{port} is not avaiable!"
					netstats_check = false
					end_loop = true
				end
			end	
		end
		puts ""
		return netstats_check
	end

	def check_list_task_info_status(node_id, component_name)
		puts "List task info check:", "---------------------"
		list_task_info_check = false

		response = send_request('/rest/node/task_status', {:node_id=>node_id, :format=>:list})
		puts "List task info check:"
		pretty_print_JSON(response)
		config_node_content = response['data']['actions'].last
		component_content = config_node_content['nodes'].first

		if (component_content['components'].select { |x| x['component']['component_name'].include? component_name}.first)
			component = component_content['components'].select { |x| x['component']['component_name'] == component_name && x['component']['source'] == 'instance' && x['component']['node_group'].nil?}.first
			pretty_print_JSON(component)

			if (!component.nil?)
				puts "List task info contains component #{component_name} from source=instance and node_group=nil"
				list_task_info_check = true
			else
				puts "List task info does not contain component #{component_name} from source=instance and node_group=nil"
			end
		else
			puts "List task info does not contain component #{component_name}"
		end
		puts ""
		return list_task_info_check
	end	

#Following list of methods is used for interaction with provider/target functionality
	
	def create_target(provider_name, region)
		puts "Create target:", "--------------"
		target_created = false
		list_providers = send_request('/rest/target/list', {:subtype => :template})
		if (list_providers['data'].select { |x| x['display_name'].include? provider_name}.first)
			puts "Provider #{provider_name} exists! Create target for provider..."
			provider_id = list_providers['data'].select { |x| x['display_name'].include? provider_name}.first['id']	
			create_target_response = send_request('/rest/target/create', {:target_name => provider_name, :target_template_id => provider_id, :region => region})
			target_created = create_target_response['data']['success']
			puts "Target #{provider_name}-#{region} created successfully!"
		else
			puts "Provider #{provider_name} does not exist!"
		end
		puts ""
		return target_created
	end

	def check_if_target_exists_in_provider(provider_name, target_name)
		puts "Check if target exists in provider:", "-----------------------------------"
		target_exists = false
		list_providers = send_request('/rest/target/list', {:subtype => :template})

		if (list_providers['data'].select { |x| x['display_name'].include? provider_name}.first)
			puts "Provider #{provider_name} exists! Get provider's targets..."
			provider_id = list_providers['data'].select { |x| x['display_name'].include? provider_name}.first['id']	
			list_targets = send_request('/rest/target/list', {:subtype => :instance, :parent_id => provider_id})

			if (list_targets['data'].select { |x| x['display_name'].include? target_name}.first)
				puts "Target #{target_name} exists in #{provider_name} provider!"
				target_exists = true
			else
				puts "Target #{target_name} does not exist in #{provider_name} provider!"
			end
		else
			puts "Provider #{provider_name} does not exist!"
		end
		puts ""
		return target_exists
	end

	def delete_target_from_provider(target_name)
		puts "Delete target from provider:", "----------------------------"
		target_deleted = false

		delete_target = send_request('/rest/target/delete', {:target_id => target_name})
		if delete_target['status'] == "ok"
			puts "Target #{target_name} has been deleted successfully!"
			target_deleted = true
		else
			puts "Target #{target_name} has not been deleted successfully!"
		end
		puts ""
		return target_deleted
	end

	def check_if_assembly_exists_in_target(assembly_name, target_name)
		puts "Check if assembly exists in target:", "-----------------------------------"
		assembly_exists = false
		assembly_list = send_request('/rest/target/info_about', {:target_id => target_name, :about => "assemblies"})
		
		if (assembly_list['data'].select { |x| x['display_name'].include? assembly_name}.first)
			puts "Assembly #{assembly_name} exists in target #{target_name}!"
			assembly_exists = true
		else
			puts "Assembly #{assembly_name} does not exist in target #{target_name}!"
		end
		puts ""
		return assembly_exists
	end

	def check_if_node_exists_in_target(node_name, target_name)
		puts "Check if node exists in target:", "-------------------------------"
		node_exists = false
		node_list = send_request('/rest/target/info_about', {:target_id => target_name, :about => "nodes"})
		
		if (node_list['data'].select { |x| x['display_name'].include? node_name}.first)
			puts "Node #{node_name} exists in target #{target_name}!"
			node_exists = true
		else
			puts "Node #{node_name} does not exist in target #{target_name}!"
		end
		puts ""
		return node_exists
	end	

	def stage_service_in_specific_target(target_name)
		#Get list of assemblies, extract selected assembly, stage service to defined target and return its service id
		puts "Stage service in specific target:", "---------------------------------"
		service_id = nil
		extract_id_regex = /id: (\d+)/
		assembly_list = send_request('/rest/assembly/list', {:subtype=>'template'})
 
		puts "List of avaliable assemblies: "
		pretty_print_JSON(assembly_list)

		test_template = assembly_list['data'].select { |x| x['display_name'] == @assembly }.first

		if (!test_template.nil?)
			puts "Assembly #{@assembly} found!"
			assembly_id = test_template['id']
			puts "Assembly id: #{assembly_id}"

			stage_service_response = send_request('/rest/assembly/stage', {:assembly_id=>assembly_id, :name=>@service_name, :target_id => target_name})
			if (stage_service_response['data'].include? "name: #{@service_name}")
				puts "Stage of #{@assembly} assembly completed successfully!"
				service_id_match = stage_service_response['data'].match(extract_id_regex)
				self.service_id = service_id_match[1].to_i
				puts "Service id for a staged service: #{self.service_id}"
			else
				puts "Stage service didnt pass!"
			end
		else
			puts "Assembly #{@assembly} not found!"
		end
		puts ""
	end

#Following list of methods is used for interaction with workspace context

	#Method to get workspace id for further interaction with workspace
	def get_workspace_id
		response = send_request('/rest/assembly/list_with_workspace', {})
		workspace = response['data'].select { |x| x['display_name'] == "workspace"}.first['id']
		return workspace
	end

	#Method used to purge content of assembly or workspace
	def purge_content(service_id)
		puts "Purge content:", "--------------"
		content_purged = false

		response = send_request('/rest/assembly/purge', {:assembly_id=>service_id})
		if response['status'].include? "ok"
			puts "Content has been purged successfully!"
			content_purged = true
		else
			puts "Content has not been purged successfully!"
		end
		puts ""
		return content_purged
	end

	def delete_node(service_id, node_name)
		puts "Delete node:", "------------"
		node_deleted = false

		delete_node_response = send_request('/rest/assembly/delete_node', {:assembly_id=>service_id, :node_id=>node_name})

		if (delete_node_response['status'] == "ok")
			puts "Node deleted successfully!"
			node_deleted = true
		else
			puts "Node was not deleted successfully!"
		end
		puts ""
		return node_deleted
	end

	def create_node(service_id, node_name, node_template)
		puts "Create node:","------------"
		create_node_response = send_request('/rest/assembly/add_node', {:assembly_id=>service_id, :assembly_node_name=>node_name, :node_template_identifier=>node_template})
		if create_node_response['status'].include? "ok"
			puts "Node #{node_name} has been created successfully!"
			puts ""
			return create_node_response['data']['guid']
		else
			puts "Node #{node_name} has not been created successfully!"
			puts ""
			return nil
		end
	end

	def check_if_node_exists_by_node_name(service_id, node_name)
		puts "Check if node exists by name:", "-----------------------------"
		node_exists = false
		node_list = send_request('/rest/assembly/info_about', {:assembly_id=>service_id, :subtype=>'instance', :about=>'nodes'})
		pretty_print_JSON(node_list)
		node = node_list['data'].select { |x| x['display_name'] == node_name }.first	
		
		if !node.nil?
			puts "Node #{node_name} exists!"
			node_exists = true
		else
			puts "Node #{node_name} does not exist!"
		end
		puts ""
		return node_exists
	end

	def add_component_to_service_node(service_id, node_name, component_id)
		puts "Add component to node:", "----------------------"
		component_added = false

		node_list = send_request('/rest/assembly/info_about', {:assembly_id=>service_id, :subtype=>'instance', :about=>'nodes'})
		puts "Node list:"
		pretty_print_JSON(node_list)
		node_id = node_list['data'].select { |x| x['display_name'] == node_name }.first['id']

		component_add_response = send_request('/rest/assembly/add_component', {:assembly_id=>service_id, :node_id=>node_id, :component_template_id=>component_id})

		if (component_add_response['status'] == 'ok')
			component_list_response = send_request('/rest/assembly/info_about', {:assembly_id=>service_id, :about=>'components', :subtype=>'instance'})
			component = component_list_response['data'].select {|x| x['id'] == component_add_response['data']['component_id']}
			if !component.empty?
				puts "Component #{component.first['display_name']} has been added to assembly node!"
				component_added = true
			else
				puts "Component has not been added to assembly node!"
			end
		end
		puts ""
		return component_added
	end

	def check_service_info(service_id, info_to_check)
		puts "Show service info:", "------------------"
		info_exist = false
		service_info_response = send_request('/rest/assembly/info', {:assembly_id=>service_id, :subtype=>:instance})
		pretty_print_JSON(service_info_response)
		if service_info_response['data'].include? info_to_check
			puts "#{info_to_check} exists in info output!"
			info_exist = true
		else
			puts "#{info_to_check} does not exist in info output!"
		end
		puts ""
		return info_exist
	end

	def check_components_presence_in_nodes(service_id, node_name, component_name_to_check)
		puts "Check components presence in nodes:", "-----------------------------------"
		component_check = false
		puts "List of assembly components:"
		service_components = send_request('/rest/assembly/info_about', {:assembly_id=>service_id, :filter=>nil, :about=>'components', :subtype=>'instance'})
		pretty_print_JSON(service_components)
		component_name = service_components['data'].select { |x| x['display_name'] == "#{node_name}/#{component_name_to_check}" }.first

		if (!component_name.nil?)
			component_check = true
			puts "Component with name: #{component_name_to_check} exists!"
		else
			component_check = false
			puts "Node with name #{node_name} or component with name #{component_name_to_check} does not exist!"
		end
		puts ""
		return component_check
	end

	def delete_component_from_service_node(service_id, node_name, component_to_delete)
		puts "Delete component from service node:", "-----------------------------------"
		component_deleted = false
		puts "List of service components:"
		service_components = send_request('/rest/assembly/info_about', {:assembly_id=>service_id, :filter=>nil, :about=>'components', :subtype=>'instance'})
		pretty_print_JSON(service_components)

		component = service_components['data'].select { |x| x['display_name'] == "#{node_name}/#{component_to_delete}" }.first

		if !component.nil?
			node_list = send_request('/rest/assembly/info_about', {:assembly_id=>service_id, :subtype=>'instance', :about=>'nodes'})
			node_id = node_list['data'].select { |x| x['display_name'] == node_name }.first['id']

			puts "Deleting component #{component_to_delete} from node #{node_name}..."
			component_delete_response = send_request('/rest/assembly/delete_component', {:assembly_id=>service_id, :node_id=>node_id, :component_id=>component['id']})
			pretty_print_JSON(component_delete_response)
			if component_delete_response['status'].include? 'ok'
				puts "Component #{component_to_delete} has been deleted successfully!"
				component_deleted = true
			else
				puts "Component #{component_to_delete} has not been deleted successfully!"
			end
		else
			puts "Component #{component_to_delete} does not exist on #{node_name} and therefore cannot be deleted!"
		end
		puts ""
		return component_deleted
	end

	def create_attribute(service_id, attribute_name)
		#Create attribute
		puts "Create attribute:", "-----------------"
		attributes_created = false

		create_attribute_response = send_request('/rest/assembly/set_attributes', {:assembly_id=>service_id, :create=>true, :pattern=>attribute_name})

		puts "List of service attributes:"
		service_attributes = send_request('/rest/assembly/info_about', {:about=>'attributes', :filter=>nil, :subtype=>'instance', :assembly_id=>service_id})
		pretty_print_JSON(service_attributes)
		extract_attribute = service_attributes['data'].select { |x| x['display_name'].include? attribute_name }.first['display_name']

		if (extract_attribute == attribute_name)
			puts "Creating #{attribute_name} attribute completed successfully!"
			attributes_created = true
		end
		puts ""
		return attributes_created
	end

	def check_if_attribute_exists(service_id, attribute_name)
		puts "Check if attribute exists:", "--------------------------"
		attribute_exists = false

		puts "List of service attributes:"
		service_attributes = send_request('/rest/assembly/info_about', {:about=>'attributes', :filter=>nil, :subtype=>'instance', :assembly_id=>service_id})
		pretty_print_JSON(service_attributes)
		extract_attribute = service_attributes['data'].select { |x| x['display_name'].include? attribute_name }.first['display_name']

		if (extract_attribute == attribute_name)
			puts "#{attribute_name} attribute exists!"
			attribute_exists = true
		else
			puts "#{attribute_name} attribute does not exist!"
		end
		puts ""
		return attribute_exists
	end

	def link_attributes(service_id, source_attribute, target_attribute)
		puts "Link attributes:", "----------------"
		attributes_linked = false

		link_attributes_response = send_request('/rest/assembly/add_ad_hoc_attribute_links', {:assembly_id=>service_id, :target_attribute_term=>target_attribute, :source_attribute_term=>"$#{source_attribute}"})
		pretty_print_JSON(link_attributes_response)

		if link_attributes_response['status'] == 'ok'
			puts "Link between #{source_attribute} attribute and #{target_attribute} attribute is established!"
			attributes_linked = true
		else
			puts "Link between #{source_attribute} attribute and #{target_attribute} attribute is not established!"
		end
		puts ""
		return attributes_linked
	end

	def netstats_check_for_specific_node(service_id, node_name, port)
		puts "Netstats check:", "---------------"

		node_list = send_request('/rest/assembly/info_about', {:assembly_id=>service_id, :subtype=>'instance', :about=>'nodes'})
		node_id = node_list['data'].select { |x| x['display_name'] == node_name }.first['id']
 		
 		netstats_check = false
		end_loop = false
		count = 0
		max_num_of_retries = 15

		while (end_loop == false)
			sleep 10
			count += 1

			if (count > max_num_of_retries)
				puts "Max number of retries for getting netstats reached..."
				end_loop = true
			end

			response = send_request('/rest/assembly/initiate_get_netstats', {:node_id=>node_id, :assembly_id=>service_id})
			action_results_id = response['data']['action_results_id']

			5.downto(1) do |i|
				sleep 1
				response = send_request('/rest/assembly/get_action_results', {:disable_post_processing=>false, :return_only_if_complete=>true, :action_results_id=>action_results_id})
				puts "Netstats check:"
				pretty_print_JSON(response)

				if response['data']['is_complete']
					port_to_check = response['data']['results'].select { |x| x['port'] == port}.first

					if (!port_to_check.nil?)
						puts "Netstats check completed! Port #{port} available!"
						netstats_check = true
						end_loop = true
						break
					else					
						puts "Netstats check completed! Port #{port} is not available!"
						netstats_check = false
						break
					end
				end				
			end	
		end
		puts ""
		return netstats_check
	end
end