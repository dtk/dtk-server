#Common class used for login on dtk application and methods for stage, converge and destroy assemblies

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'

class DtkCommon

	$success == true
	$log = '/var/log/thin.log'
	$local_vars_array = Array.new()
	attr_accessor :assembly_name, :assembly_template, :SERVER, :PORT, :ENDPOINT, :USERNAME, :PASSWORD, :success

	$opts = {
				 :timeout => 100,
			:open_timeout => 50,
				 :cookies => {}
	}

	#Constructor
	def initialize(assembly_name, assembly_template)
		#Initialize variables
		@assembly_name = assembly_name
		@assembly_template = assembly_template
		@SERVER = 'dev10.r8network.com'
		@PORT = 7000
		@ENDPOINT = "http://dev10.r8network.com:7000"
		@USERNAME = 'dtk10'
		@PASSWORD = 'r8server'

		#Login to dtk application
		response_login = RestClient.post(@ENDPOINT + '/rest/user/process_login', 'username' => @USERNAME, 'password' => @PASSWORD, 'server_host' => @SERVER, 'server_port' => @PORT)
		$cookies = response_login.cookies
		$opts[:cookies] = response_login.cookies
	end

	def send_request(path, body)
		#Accessing inner class Resource from RestClient class
		resource = ::RestClient::Resource.new(@ENDPOINT + path, $opts)
		request_response = resource.post(body)
		request_response_JSON = JSON.parse(request_response)

		#If response contains errors, accumulate all errors to error_message
		unless request_response_JSON["errors"].nil? 
			error_message = ""
			request_response_JSON["errors"].each { |e| error_message += "#{e['code']}: #{e['message']} "}
		end

		#If response status notok, success = false, show error_message
		if (request_response_JSON["status"] == "notok")
			$success = false
			puts "", "Request failed!"
			puts error_message
			unless request_response_JSON["errors"].first["backtrace"].nil? 
				puts "", "Backtrace:"
				pretty_print_JSON(request_response_JSON["errors"].first["backtrace"])
			end

			log_print()
		end
		return request_response_JSON
	end

	def pretty_print_JSON(json_content)
		return ap json_content
	end

	def stage_assembly()
		#Get list of assembly templates and extract selected template and its assembly id
		assembly_id = nil
		assembly_template_list = send_request('/rest/assembly/list', {:subtype=>'template'})
		test_template = assembly_template_list['data'].select { |x| x['display_name'] == @assembly_template }

		template_assembly_id = test_template.first['id']
		puts "Assembly Template id: #{template_assembly_id}"

		#Stage assembly and return assembly id
		stage_assembly_response = send_request('/rest/assembly/stage', {:assembly_id=>template_assembly_id, :name=>@assembly_name})		

		if (stage_assembly_response['data']['assembly_id'])
			assembly_id = stage_assembly_response['data']['assembly_id']
			puts "Assembly id: #{assembly_id}"
		else
			puts "Stage assembly didnt pass"
		end
		return assembly_id
	end

	def check_if_assembly_exists(assembly_id)
		#Get list of assemblies and check if staged assembly exists
		assembly_exists = false
		assembly_list = send_request('/rest/assembly/list', {:detail_level=>'nodes', :subtype=>'instance'})
		test_assembly = assembly_list['data'].select { |x| x['id'] == assembly_id }

		puts "Assembly with id #{assembly_id}: "
		pretty_print_JSON(test_assembly)

		if (test_assembly.any?)	
			extract_assembly_id = test_assembly.first['id']
			execution_status = test_assembly.first['execution_status']

			if ((extract_assembly_id == assembly_id) && (execution_status == 'staged'))
				assembly_exists = true
			end
		end
		return assembly_exists
	end

	def check_assembly_status(assembly_id, status_to_check)
		#Get list of assemblies and check if assembly exists and its status
		assembly_exists = false
		end_loop = false
		count = 0
		max_num_of_retries = 50

		while (end_loop == false)
			sleep 5
			count += 1

			assembly_list = send_request('/rest/assembly/list', {:subtype=>'instance'})
			test_assembly = assembly_list['data'].select { |x| x['id'] == assembly_id }

			"Assembly info:"
			puts send_request('/rest/assembly/info', {:assembly_id=>assembly_id,:subtype=>:instance})

			if (test_assembly.any?)
				extract_assembly_id = test_assembly.first['id']
				op_status = test_assembly.first['op_status']
				puts "Assembly found: #{extract_assembly_id} with op status #{op_status}"

				if ((extract_assembly_id == assembly_id) && (op_status == status_to_check))
					assembly_exists = true
					end_loop = true
				end			
			else
				puts "Assembly with id #{assembly_id} not found in list"
				assembly_exists = false
				end_loop = true		
			end
			
			if (count > max_num_of_retries)
				puts "Max number of retries reached..."
				end_loop = true 
				assembly_exists = false
			end				
		end

		return assembly_exists
	end

	def set_attribute(assembly_id, attribute_name, attribute_value)
		is_attributes_set = false

		#Get attribute id for which value will be set
		assembly_attributes = send_request('/rest/assembly/info_about', {:about=>'attributes', :filter=>nil, :subtype=>'instance', :assembly_id=>assembly_id})
		pretty_print_JSON(assembly_attributes)
		attribute_id = assembly_attributes['data'].select { |x| x['display_name'].include? attribute_name }.first['id']

		#Set attribute value for given attribute id
		set_attribute_value_response = send_request('/rest/assembly/set_attributes', {:assembly_id=>assembly_id, :value=>attribute_value, :pattern=>attribute_id})
		extract_attribute_value = set_attribute_value_response['data'].first['value']

		if (extract_attribute_value == attribute_value)
			puts "Setting of #{attribute_name} attribute completed successfully"
			is_attributes_set = true
		end

		return is_attributes_set
	end

	def check_attribute_presence_in_nodes(assembly_id, node_name, attribute_name_to_check, attribute_value_to_check)
		attribute_check = false

		#Get attribute and check if attribute name and attribute value exists
		assembly_attributes = send_request('/rest/assembly/info_about', {:assembly_id=>assembly_id, :filter=>nil, :about=>'attributes', :subtype=>'instance'})

		pretty_print_JSON(assembly_attributes)

		#Check if node exists
		if (assembly_attributes['data'].select { |x| x['display_name'] == "node[#{node_name}]/#{attribute_name_to_check}" }.first)		
			attribute_name = assembly_attributes['data'].select { |x| x['display_name'] == "node[#{node_name}]/#{attribute_name_to_check}" }.first['display_name']
			attribute_value = assembly_attributes['data'].select { |x| x['value'] == attribute_value_to_check }.first['value']

			if ((attribute_name.include? attribute_name_to_check) && (attribute_value == attribute_value_to_check))
				puts "Attribute #{attribute_name_to_check} with value #{attribute_value_to_check} exists" 
				attribute_check = true
			elsif ((attribute_name.include? attribute_name_to_check) && (attribute_value_to_check == ''))
				puts "Attribute #{attribute_name_to_check} exists" 
				attribute_check = true
			else
				puts "Node with name #{node_name} does not exist!"
				attribute_check = false
			end
		end

		return attribute_check
	end

	def check_attribute_presence_in_components(assembly_id, node_name, component_name, attribute_name_to_check, attribute_value_to_check)
		attribute_check = false

		#Get attribute and check if attribute name and attribute value exists
		assembly_attributes = send_request('/rest/assembly/info_about', {:assembly_id=>assembly_id, :filter=>nil, :about=>'attributes', :subtype=>'instance'})
		pretty_print_JSON(assembly_attributes)

		#Check if node exists
		if (assembly_attributes['data'].select { |x| x['display_name'] == "node[#{node_name}]/cmp[#{component_name}]/#{attribute_name_to_check}" }.first)		
			attribute_name = assembly_attributes['data'].select { |x| x['display_name'] == "node[#{node_name}]/cmp[#{component_name}]/#{attribute_name_to_check}" }.first['display_name']
			
			if ((attribute_name.include? attribute_name_to_check) && (attribute_value_to_check == ''))
				puts "Attribute #{attribute_name_to_check} exists" 
				attribute_check = true
			elsif ((attribute_name.include? attribute_name_to_check) && (attribute_value = assembly_attributes['data'].select { |x| x['value'] == attribute_value_to_check }.first['value']))
				puts "Attribute #{attribute_name_to_check} with value #{attribute_value_to_check} exists" 
				attribute_check = true
			else
				puts "Attribute #{attribute_name_to_check} does not exist"
				attribute_check = false
			end
		else
			puts "Attribute #{attribute_name_to_check} does not exist in component #{component_name}"
		end

		return attribute_check
	end

	def check_components_presence_in_nodes(assembly_id, node_name, component_name_to_check)
		component_check = false
		assembly_components = send_request('/rest/assembly/info_about', {:assembly_id=>assembly_id, :filter=>nil, :about=>'components', :subtype=>'instance'})
		pretty_print_JSON(assembly_components)
		component_name = assembly_components['data'].select { |x| x['display_name'] }.first['display_name']

		#Check if node exists
		if (component_name == "#{node_name}/#{component_name_to_check}")
			component_check = true
			puts "Component with name: #{component_name_to_check} exists!"
		else
			component_check = false
			puts "Node with name #{node_name} or component with name #{component_name_to_check} does not exist!"
		end

		return component_check
	end

	def check_params_presence_in_nodes(assembly_id, node_name, param_name_to_check, param_value_to_check)
		param_check = false
		assembly_nodes = send_request('/rest/assembly/info_about', {:assembly_id=>assembly_id, :filter=>nil, :about=>'nodes', :subtype=>'instance'})

		pretty_print_JSON(assembly_nodes)

		#Check if node exists
 		if (assembly_nodes['data'].select { |x| x['display_name'] == node_name }.first)
			parameter = assembly_nodes['data'].select { |x| x['display_name'] == node_name }.first[param_name_to_check]

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
		return param_check
	end

	def converge_assembly(assembly_id)
		create_task_response = send_request('/rest/assembly/create_task', {'assembly_id' => assembly_id})
		task_id = create_task_response['data']['task_id']
		task_execute_response = send_request('/rest/task/execute', {'task_id' => task_id})

		task_status = 'executing'
		while task_status.include? 'executing'
			sleep 20
			response_task_status = send_request('/rest/task/status', {'task_id'=> task_id})
			status = response_task_status['data']['status']
			if (status.include? 'succeeded')
				task_status = status
			elsif (status.include? 'failed')
				task_status = status
				log_print()
			end
			puts "Task execution status: #{task_status}"
		end

		return task_status
	end

	def stop_running_assembly(assembly_id)
		stop_assembly_response = send_request('/rest/assembly/stop', {'assembly_id' => assembly_id})
		return stop_assembly_response['data']['status']
	end

	def start_running_assembly(assembly_id)
		response = send_request('/rest/assembly/start', {'assembly_id' => assembly_id, :node_pattern=>nil})
		action_results_id = response['data']['action_results_id']
		start_instance = 'not_started'
		end_loop = false
		count = 0
		max_num_of_retries = 100

		while (end_loop == false)
			response = send_request('/rest/assembly/get_action_results', {:using_simple_queue=>true, :action_results_id=>action_results_id})
			puts "Start instance check: #{response}"
			count += 1
			if (count > max_num_of_retries)
				puts "Max number of retries for starting instance reached..."
				end_loop = true
			elsif (response['data']['result'] != nil)
				puts "Instance started!"
				start_instance = response['status']
				end_loop = true
			end				
		end
		return start_instance
	end

	def delete_and_destroy_assembly(assembly_id)
		#Cleanup step - Delete and destroy assembly
		delete_assembly_response = send_request('/rest/assembly/delete', {:assembly_id=>assembly_id})
		return delete_assembly_response['status']
	end

	def delete_assembly_template(assembly_template_name)
		#Cleanup step - Delete assembly template
		assembly_template_list = send_request('/rest/assembly/list', {:detail_level=>"nodes", :subtype=>"template"})
		assembly_template_id = assembly_template_list['data'].select { |x| x['display_name'] == assembly_template_name }.first['id']
		delete_assembly_template_response = send_request('/rest/assembly/delete', {:assembly_id=>assembly_template_id, :subtype=>:template})
		return delete_assembly_template_response['status']
	end

	def create_assembly_template_from_assembly(assembly_id, service_name, assembly_template_name)
		template_created = false	
		create_assembly_template_response = send_request('/rest/assembly/create_new_template', {:service_module_name=>service_name, :assembly_id=>assembly_id, :assembly_template_name=>assembly_template_name})
		if (create_assembly_template_response['status'] == 'ok')
			puts "Assembly template #{assembly_template_name} created in service #{service_name}"
			template_created = true
		else
			puts "Assembly template #{assembly_template_name} was not created in service #{service_name}" 
			template_created = true
		end
		return template_created
	end

	def netstats_check(assembly_id)
		response = send_request('/rest/assembly/initiate_get_netstats', {:node_id=>nil, :assembly_id=>assembly_id})
		action_results_id = response['data']['action_results_id']

		netstat_response = 'no_response'
		end_loop = false
		count = 0
		max_num_of_retries = 50

		while (end_loop == false)
			sleep 20
			response = send_request('/rest/assembly/get_action_results', {:disable_post_processing=>false, :return_only_if_complete=>true, :action_results_id=>action_results_id})
			puts "Netstats check: #{response}"
			count += 1
			if (count > max_num_of_retries)
				puts "Max number of retries for getting netstats reached..."
				end_loop = true
			elsif (response['data']['is_complete'])
				netstat_response = response
				end_loop = true
			end	
		end

		return netstat_response
	end

	def log_print()
		start_line = 1
		search_string = "Exiting"

		#get lines of the file into an array (chomp optional)
		lines = File.readlines($log).map(&:chomp)

		#"cut" the deck, as with playing cards, so start_line is first in the array
		lines = lines.slice!(start_line..lines.length) + lines

		#searching backwards can just be searching a reversed array forwards
		lines.reverse!

		#search through the reversed-array, for the first occurence
		reverse_occurence = nil
		lines.each_with_index do |line,index|
			if line.include?(search_string)
				reverse_occurence = index
				break
			end
		end

		#reverse_occurence is now either "nil" for no match, or a reversed-index
		#also un-cut the array when calculating the index
		if reverse_occurence
			occurence = lines.size - reverse_occurence - 1 + start_line
			line = lines[reverse_occurence]
			puts "---------------------------------------------------------------------------------------------------------------"
			puts "Matched #{search_string} on line #{occurence}"
			puts line
			lines.reverse!
			puts "Server log data since the last restart:"
			puts lines[occurence..(lines.size - 2)]
		end
	end

	def import_remote_module(module_to_import)
		module_imported = false
		modules_list = send_request('/rest/component_module/list', {})
		
		if (modules_list['data'].select { |x| x['display_name'] == module_to_import }.first)
			puts "Module #{module_to_import} already exists in module list."
			module_imported = false
		else
			puts "Module not found in module list. Check module exist on remote repo..."
			remote_modules_list = send_request('/rest/component_module/list_remote', {})

			if (remote_modules_list['data'].select { |x| x['display_name'].include? module_to_import}.first)
				puts "Module specified found in list of remote modules. Try to import module..."
				import_response = send_request('/rest/component_module/import', {:remote_module_name=>module_to_import, :local_module_name=>module_to_import})
				puts "Module import response:"
				pretty_print_JSON(import_response)
				modules_list = send_request('/rest/component_module/list', {})
				puts "Module list response:"
				pretty_print_JSON(modules_list)

				if (import_response['status'] == 'ok' && modules_list['data'].select { |x| x['display_name'] == module_to_import }.first)
					puts "Module imported successfully from remote repo."
					module_imported = true
				else
					puts "Module was not imported from remote repo successfully."
					module_imported = false
				end
			else
				puts "Module specified was not found in list of remote modules."				
				module_imported = false
			end
		end
		return module_imported
	end

	def export_module_to_remote(module_to_export, namespace)
		module_exported = false
		modules_list = send_request('/rest/component_module/list', {})

		if (modules_list['data'].select { |x| x['display_name'] == module_to_export }.first)
			puts "Module #{module_to_export} exists in module list. Check if module exists on remote repo already..."
			remote_modules_list = send_request('/rest/component_module/list_remote', {})

			if (remote_modules_list['data'].select { |x| x['display_name'].include? module_to_export}.first)
   			puts "Module #{module_to_export} was found in list of remote modules."
   			module_exported = false
			else
				puts "Module #{module_to_export} was not found in list of remote modules. Proceed with export of module..."
				component_module_id = modules_list['data'].select { |x| x['display_name'] == module_to_export}.first['id']				
				export_response = send_request('/rest/component_module/export', {:remote_component_name=>module_to_export, :component_module_id=>component_module_id, :remote_component_namespace=>namespace})

				puts "Module export response:"
				pretty_print_JSON(export_response)

				remote_modules_list = send_request('/rest/component_module/list_remote', {})
				if (remote_modules_list['data'].select { |x| x['display_name'].include? module_to_export}.first)
					puts "Module #{module_to_export} exported successfully in namespace #{namespace}"
					module_exported = true
				else
					puts "Module #{module_to_export} was not exported successfully in namespace #{namespace}"
					module_exported = false
				end			
			end
		else
			puts "Module #{module_to_export} not found in module list and therefore cannot be exported"
			module_exported = false
		end
		return module_exported
	end

	def get_module_components_list(module_name, filter_version)
		component_ids_list = Array.new()
		modules_list = send_request('/rest/component_module/list', {})

		puts modules_list

		if (modules_list['data'].select { |x| x['display_name'] == module_name}.first)
			puts "Module #{module_name} exists in the list. Get component module id..."
			component_module_id = modules_list['data'].select { |x| x['display_name'] == module_name}.first['id']
			puts component_module_id
			module_components_list = send_request('/rest/component_module/info_about', {:about=>"components", :component_module_id=>component_module_id})
			pretty_print_JSON(module_components_list)

			module_components_list['data'].each do |x|
				if (filter_version != "")
					component_ids_list << x['id'] if x['version'] == filter_version
				else
					component_ids_list << x['id']
				end
			end
		end
		return component_ids_list
	end

	def check_if_component_exists_in_module(module_name, filter_version, component_name)
		component_exists_in_module = false
		component_names_list = Array.new()
		modules_list = send_request('/rest/component_module/list', {})

		if (modules_list['data'].select { |x| x['display_name'] == module_name}.first)
			puts "Module #{module_name} exists in the list. Get component module id..."
			component_module_id = modules_list['data'].select { |x| x['display_name'] == module_name}.first['id']
			module_components_list = send_request('/rest/component_module/info_about', {:about=>"components", :component_module_id=>component_module_id})
			pretty_print_JSON(module_components_list)

			module_components_list['data'].each do |x|
				if (filter_version != "")
					component_names_list << x['display_name'] if x['version'] == filter_version
				else
					component_names_list << x['display_name']
				end
			end
		end

		component_exists_in_module = true if component_names_list.include? component_name
		return component_exists_in_module
	end

	def add_component_to_assembly_node(assembly_id, node_name, component_id)
		component_added = false
		assembly_nodes = send_request('/rest/assembly/info_about', {:assembly_id=>assembly_id, :filter=>nil, :about=>'nodes', :subtype=>'instance'})
		if (assembly_nodes['data'].select { |x| x['display_name'] == node_name }.first)
			puts "Node #{node_name} exists in assembly. Get node id..."
			node_id = assembly_nodes['data'].select { |x| x['display_name'] == node_name }.first['id']
			component_add_response = send_request('/rest/assembly/add_component', {:node_id=>node_id, :component_template_id=>component_id, :assembly_id=>assembly_id})

			if (component_add_response['status'] == 'ok')
				puts "Component added to assembly"
				component_added = true
			end
		end
		return component_added
	end

	def delete_module(module_to_delete)
		module_deleted = false
		modules_list = send_request('/rest/component_module/list', {})

		if (modules_list['data'].select { |x| x['display_name'] == module_to_delete }.first)
			puts "Module exists in module list. Try to delete module..."
			delete_response = send_request('/rest/component_module/delete', {:component_module_id=>module_to_delete})
			pretty_print_JSON(delete_response)

			if (delete_response['status'] == 'ok' && modules_list['data'].select { |x| x['module_name'] == nil })
				puts "Module deleted successfully"
				module_deleted = true
			else
				puts "Module was not deleted successfully"
				module_deleted = false
			end
		else
			puts "Module does not exist in module list and therefore cannot be deleted."
			module_deleted = false
		end
		return module_deleted
	end

	def create_new_module_version(module_name, version)
		module_versioned = false
		modules_list = send_request('/rest/component_module/list', {})

		if (modules_list['data'].select { |x| x['display_name'] == module_name }.first)
			puts "Module exists in module list. Try to version module..."
			module_id = modules_list['data'].select { |x| x['display_name'] == module_name }.first['id']
			versioning_response = send_request('/rest/component_module/create_new_version', {:version=>version, :component_module_id=>module_id})
			puts "Versioning response:"
			pretty_print_JSON(versioning_response)
			puts "Module list response:"
			modules_list = send_request('/rest/component_module/list', {})
			pretty_print_JSON(modules_list)

			if (versioning_response['status'] == 'ok' && modules_list['data'].select { |x| (x['display_name'] == module_name) && (x['version'].include? version) }.first)
				puts "Module versioned successfully."
				module_versioned = true
			else
				puts "Module was not versioned successfully."
				module_versioned = false
			end
		else
			puts "Module does not exist in module list and therefore cannot be versioned."
			module_versioned = false
		end
		return module_versioned
	end

	def import_versioned_module_from_remote(module_name, version)
		module_imported = false
		modules_list = send_request('/rest/component_module/list', {})

		if (modules_list['data'].select { |x| x['display_name'] == module_name }.first)
			puts "Module exists in module list. Try to import versioned module..."
			module_id = modules_list['data'].select { |x| x['display_name'] == module_name }.first['id']
			import_response = send_request('/rest/component_module/import_version', {:version=>version, :component_module_id=>module_id})
			puts "Import versioned module response:"
			pretty_print_JSON(import_response)
			puts "Module list response:"
			modules_list = send_request('/rest/component_module/list', {})
			pretty_print_JSON(modules_list)

			if (import_response['status'] == 'ok' && modules_list['data'].select { |x| (x['display_name'] == module_name) && (x['version'].include? version) }.first)
				puts "Versioned module imported successfully."
				module_imported = true
			else
				puts "Versioned module was not imported successfully."
				module_imported = false
			end
		else
			puts "Module does not exist in module list and therefore versioned module cannot be imported."
			module_imported = false
		end
		return module_imported
	end

	def create_new_service(service_name)
		service_created = false
		service_list = send_request('/rest/service_module/list', {})

		if (service_list['data'].select { |x| x['display_name'] == service_name }.first)
			puts "Service already exists with name #{service_name}."
		else
			puts "Service does not exist. Try to create service with name #{service_name}..."
			create_service_response = send_request('/rest/service_module/create', {:module_name=>service_name})
			puts "Service create response:"
			pretty_print_JSON(create_service_response)

			service_module = create_service_response['data']['service_module_id']
			service_list = send_request('/rest/service_module/list', {})
			puts "Service list response:"
			pretty_print_JSON(service_list)

			if (service_list['data'].select { |x| x['display_name'] == service_name }.first)
				puts "New service #{service_name} added successfully."
				service_created = true
			else
				puts "New service #{service_name} was not added successfully."
			end
		end
		return service_created
	end

	def delete_service(service_name)
		service_deleted = false
		service_list = send_request('/rest/service_module/list', {})

		if (service_list['data'].select { |x| x['display_name'] == service_name }.first)
			puts "Service exists in service list. Try to delete service #{service_name}..."
			delete_service_response = send_request('/rest/service_module/delete', {:service_module_id=>service_name})
			puts "Service delete response:"
			pretty_print_JSON(delete_service_response)

			service_list = send_request('/rest/service_module/list', {})
			puts "Service list response:"
			pretty_print_JSON(service_list)

			if (delete_service_response['status'] == 'ok' && !service_list['data'].select { |x| x['display_name'] == service_name }.first)
				puts "Service #{service_name} deleted successfully."
				service_deleted = true
			else
				puts "Service #{service_name} not deleted successfully."
				service_deleted = false
			end			
		else
			puts "Service does not exist in service list."
			service_deleted = false
		end
		return service_deleted
	end

	def check_if_service_contains_assembly_template(service_name, assembly_template_name)
		service_contains_template = false
		service_list = send_request('/rest/service_module/list', {})

		if (service_list['data'].select { |x| x['display_name'] == service_name }.first)
			puts "Service exists in service list. Try to find if #{assembly_template_name} belongs to #{service_name} service..."
			service_id = service_list['data'].select { |x| x['display_name'] == service_name }.first['id']
			service_templates_list = send_request('/rest/service_module/list_assemblies', {:service_module_id=>service_id})

			if (service_templates_list['data'].select { |x| x['display_name'] == assembly_template_name }.first)
				puts "Assembly template #{assembly_template_name} belongs to #{service_name} service."
				service_contains_template = true
			else
				puts "Assembly template #{assembly_template_name} does not belong to #{service_name} service."
				service_contains_template = false
			end
		else
			puts "Service does not exist in service list."
			service_contains_template = false
		end
		return service_contains_template
	end
end