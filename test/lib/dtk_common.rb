#Common class with methods used for interaction with dtk server

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'

STDOUT.sync = true

class DtkCommon

	$success == true
	attr_accessor :assembly_name, :assembly_template, :SERVER, :PORT, :ENDPOINT, :USERNAME, :PASSWORD, :success
	attr_accessor :component_module_id_list

	$opts = {
		:timeout => 100,
		:open_timeout => 50,
		:cookies => {}
	}

	def initialize(assembly_name, assembly_template)
		@assembly_name = assembly_name
		@assembly_template = assembly_template
		@SERVER = 'dev10.r8network.com'
		@PORT = 7000
		@ENDPOINT = "http://dev10.r8network.com:7000"
		@USERNAME = 'dtk10'
		@PASSWORD = 'r8server'

		#user as placeholder for component ids for specific module that are accumulated
		@component_module_id_list = Array.new()

		#Login to dtk application
		response_login = RestClient.post(@ENDPOINT + '/rest/user/process_login', 'username' => @USERNAME, 'password' => @PASSWORD, 'server_host' => @SERVER, 'server_port' => @PORT)
		$cookies = response_login.cookies
		$opts[:cookies] = response_login.cookies
	end

	def send_request(path, body)
		resource = RestClient::Resource.new(@ENDPOINT + path, $opts)
		response = resource.post(body)
		response_JSON = JSON.parse(response)

		#If response contains errors, accumulate all errors to error_message
		unless response_JSON["errors"].nil? 
			error_message = ""
			response_JSON["errors"].each { |e| error_message += "#{e['code']}: #{e['message']} "}
		end

		#If response status notok, success = false, show error_message
		if (response_JSON["status"] == "notok")
			$success = false
			puts "", "Request failed!"
			puts error_message
			unless response_JSON["errors"].first["backtrace"].nil? 
				puts "", "Backtrace:"
				pretty_print_JSON(response_JSON["errors"].first["backtrace"])
			end
		end
		return response_JSON
	end

	def pretty_print_JSON(json_content)
		return ap json_content
	end

	def stage_assembly
		#Get list of assembly templates, extract selected template, stage assembly and return its assembly id
		puts "Stage assembly:", "---------------"
		assembly_id = nil
		assembly_template_list = send_request('/rest/assembly/list', {:subtype=>'template'})

		puts "List of avaliable assembly templates: "
		pretty_print_JSON(assembly_template_list)

		test_template = assembly_template_list['data'].select { |x| x['display_name'] == @assembly_template }.first

		if (!test_template.nil?)
			puts "Assembly template #{@assembly_template} found!"
			template_assembly_id = test_template['id']
			puts "Assembly template id: #{template_assembly_id}"

			stage_assembly_response = send_request('/rest/assembly/stage', {:assembly_id=>template_assembly_id, :name=>@assembly_name})		

			if (stage_assembly_response['data']['assembly_id'])
				puts "Stage of #{assembly_template} assembly template completed successfully!"
				assembly_id = stage_assembly_response['data']['assembly_id']
				puts "Assembly id for a staged assembly: #{assembly_id}"
			else
				puts "Stage assembly didnt pass!"
			end
		else
			puts "Assembly template #{@assembly_template} not found!"
		end
		puts ""
		return assembly_id
	end

	def check_if_assembly_exists(assembly_id)
		#Get list of existing assemblies and check if staged assembly exists
		puts "Check if assembly exists:", "-------------------------"
		assembly_exists = false
		assembly_list = send_request('/rest/assembly/list', {:detail_level=>'nodes', :subtype=>'instance'})
		test_assembly = assembly_list['data'].select { |x| x['id'] == assembly_id }

		puts "Assembly with id #{assembly_id}: "
		pretty_print_JSON(test_assembly)

		if (test_assembly.any?)	
			extract_assembly_id = test_assembly.first['id']
			execution_status = test_assembly.first['execution_status']

			if ((extract_assembly_id == assembly_id) && (execution_status == 'staged'))
				puts "Assembly with id #{assembly_id} exists!"
				assembly_exists = true
			end
		else
			puts "Assembly with id #{assembly_id} does not exist!"
		end
		puts ""
		return assembly_exists
	end

	def check_assembly_status(assembly_id, status_to_check)
		#Get list of assemblies and check if assembly exists and its status
		puts "Check assembly status:", "----------------------"
		assembly_exists = false
		end_loop = false
		count = 0
		max_num_of_retries = 50

		while (end_loop == false)
			sleep 5
			count += 1

			assembly_list = send_request('/rest/assembly/list', {:subtype=>'instance'})
			assembly = assembly_list['data'].select { |x| x['id'] == assembly_id }.first

			if (!assembly.nil?)
				test_assembly = send_request('/rest/assembly/info', {:assembly_id=>assembly_id,:subtype=>:instance})
				op_status = test_assembly['data']['op_status']
				extract_assembly_id = assembly['id']

				if ((extract_assembly_id == assembly_id) && (op_status == status_to_check))
					puts "Assembly with id #{extract_assembly_id} has current op status: #{status_to_check}"
					assembly_exists = true
					end_loop = true
				else
					puts "Assembly with id #{extract_assembly_id} still does not have current op status: #{status_to_check}"
				end		
			else
				puts "Assembly with id #{assembly_id} not found in list"
				end_loop = true		
			end
			
			if (count > max_num_of_retries)
				puts "Max number of retries reached..."
				end_loop = true 
			end				
		end
		puts ""
		return assembly_exists
	end

	def set_attribute(assembly_id, attribute_name, attribute_value)
		#Set attribute on particular assembly
		puts "Set attribute:", "--------------"
		is_attributes_set = false

		#Get attribute id for which value will be set
		puts "List of assembly attributes:"
		assembly_attributes = send_request('/rest/assembly/info_about', {:about=>'attributes', :filter=>nil, :subtype=>'instance', :assembly_id=>assembly_id})
		pretty_print_JSON(assembly_attributes)
		attribute_id = assembly_attributes['data'].select { |x| x['display_name'].include? attribute_name }.first['id']

		#Set attribute value for given attribute id
		set_attribute_value_response = send_request('/rest/assembly/set_attributes', {:assembly_id=>assembly_id, :value=>attribute_value, :pattern=>attribute_id})
		extract_attribute_value = set_attribute_value_response['data'].first['value']

		if (extract_attribute_value == attribute_value)
			puts "Setting of #{attribute_name} attribute completed successfully!"
			is_attributes_set = true
		end
		puts ""
		return is_attributes_set
	end

	def check_attribute_presence_in_nodes(assembly_id, node_name, attribute_name_to_check, attribute_value_to_check)
		puts "Check attribute presence in nodes:", "----------------------------------"		
		attribute_check = false
		#Get attribute and check if attribute name and attribute value exists
		puts "List of assembly attributes:"
		assembly_attributes = send_request('/rest/assembly/info_about', {:assembly_id=>assembly_id, :filter=>nil, :about=>'attributes', :subtype=>'instance'})
		pretty_print_JSON(assembly_attributes)

		if (assembly_attributes['data'].select { |x| x['display_name'] == "node[#{node_name}]/#{attribute_name_to_check}" }.first)		
			attribute_name = attribute_name_to_check
			attribute_value = assembly_attributes['data'].select { |x| x['value'] == attribute_value_to_check }.first

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

	def check_attribute_presence_in_components(assembly_id, node_name, component_name, attribute_name_to_check, attribute_value_to_check)
		puts "Check attribute presence in components:", "---------------------------------------"
		attribute_check = false
		#Get attribute and check if attribute name and attribute value exists
		puts "List of assembly attributes:"
		assembly_attributes = send_request('/rest/assembly/info_about', {:assembly_id=>assembly_id, :filter=>nil, :about=>'attributes', :subtype=>'instance'})
		pretty_print_JSON(assembly_attributes)

		if (assembly_attributes['data'].select { |x| x['display_name'] == "node[#{node_name}]/cmp[#{component_name}]/#{attribute_name_to_check}" }.first)		
			attribute_name = attribute_name_to_check
			attribute_value = assembly_attributes['data'].select { |x| x['value'] == attribute_value_to_check }.first

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

	def check_components_presence_in_nodes(assembly_id, node_name, component_name_to_check)
		puts "Check components presence in nodes:", "-----------------------------------"
		component_check = false
		puts "List of assembly components:"
		assembly_components = send_request('/rest/assembly/info_about', {:assembly_id=>assembly_id, :filter=>nil, :about=>'components', :subtype=>'instance'})
		pretty_print_JSON(assembly_components)
		component_name = assembly_components['data'].select { |x| x['display_name'] == "#{node_name}/#{component_name_to_check}" }.first

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

	def check_params_presence_in_nodes(assembly_id, node_name, param_name_to_check, param_value_to_check)
		puts "Check params presence in nodes:", "-------------------------------"
		param_check = false
		puts "List of assembly nodes:"
		assembly_nodes = send_request('/rest/assembly/info_about', {:assembly_id=>assembly_id, :filter=>nil, :about=>'nodes', :subtype=>'instance'})
		pretty_print_JSON(assembly_nodes)
		node_content = assembly_nodes['data'].select { |x| x['display_name'] == node_name }.first

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

	def converge_assembly(assembly_id)
		puts "Converge assembly:", "------------------"
		assembly_converged = false
		puts "Converge process for assembly with id #{assembly_id} started!"
		create_task_response = send_request('/rest/assembly/create_task', {'assembly_id' => assembly_id})
		task_id = create_task_response['data']['task_id']
		task_execute_response = send_request('/rest/task/execute', {'task_id' => task_id})

		end_loop = false
		count = 0
		max_num_of_retries = 10

		task_status = 'executing'
		while task_status.include? 'executing' || end_loop == false
			sleep 20
			count += 1
			response_task_status = send_request('/rest/task/status', {'task_id'=> task_id})
			status = response_task_status['data']['status']
			if (status.include? 'succeeded')
				task_status = status
				assembly_converged = true
				puts "Converge process finished successfully!"
			elsif (status.include? 'failed')
				task_status = status
				puts "Converge process was not finished successfully!"
			end
			puts "Task execution status: #{task_status}"

			if (count > max_num_of_retries)
				puts "Max number of retries reached..."
				puts "Converge process was not finished successfully!"
				end_loop = true 
			end
		end
		puts ""
		return assembly_converged
	end

	def stop_running_assembly(assembly_id)
		puts "Stop running assembly:", "----------------------"
		assembly_stopped = false
		stop_assembly_response = send_request('/rest/assembly/stop', {'assembly_id' => assembly_id})

		if (stop_assembly_response['data']['status'] == "ok")
			puts "Aseembly stopped successfully!"
			assembly_stopped = true
		else
			puts "Assembly was not stopped successfully!"
		end
		puts ""
		return assembly_stopped
	end

	def start_running_assembly(assembly_id)
		puts "Start assembly:", "---------------"
		assembly_started = false
		response = send_request('/rest/assembly/start', {'assembly_id' => assembly_id, :node_pattern=>nil})
		action_results_id = response['data']['action_results_id']
		end_loop = false
		count = 0
		max_num_of_retries = 50

		while (end_loop == false)
			sleep 5
		  count += 1
			response = send_request('/rest/assembly/get_action_results', {:using_simple_queue=>true, :action_results_id=>action_results_id})
			puts "Start instance check:"
			pretty_print_JSON(response)

			if (count > max_num_of_retries)
				puts "Max number of retries for starting instance reached..."
				end_loop = true
			elsif (!response['data']['result'].nil?)
				puts "Instance started!"
				assembly_started = true if response['status'] == 'ok'
				end_loop = true
			end				
		end
		puts ""
		return assembly_started
	end

	def delete_and_destroy_assembly(assembly_id)
		#Cleanup step - Delete and destroy assembly
		puts "Delete and destroy assembly:", "----------------------------"
		assembly_deleted = false
		delete_assembly_response = send_request('/rest/assembly/delete', {:assembly_id=>assembly_id})

		if (delete_assembly_response['status'] == "ok")
			puts "Assembly deleted successfully!"
			assembly_deleted = true
		else
			puts "Assembly was not deleted successfully!"
		end
		puts ""
		return assembly_deleted
	end

	def delete_assembly_template(assembly_template_name)
		#Cleanup step - Delete assembly template
		puts "Delete assembly template:", "-------------------------"
		assembly_templated_deleted = false
		assembly_template_list = send_request('/rest/assembly/list', {:detail_level=>"nodes", :subtype=>"template"})
		assembly_template_id = assembly_template_list['data'].select { |x| x['display_name'] == assembly_template_name }.first['id']
		delete_assembly_template_response = send_request('/rest/assembly/delete', {:assembly_id=>assembly_template_id, :subtype=>:template})

		if (delete_assembly_template_response['status'] == "ok")
			puts "Assembly template #{assembly_template_name} deleted successfully!"
			assembly_templated_deleted = true
		else
			puts "Assembly template #{assembly_template_name} was not deleted successfully!"
		end
		puts ""
		return assembly_templated_deleted
	end

	def create_assembly_template_from_assembly(assembly_id, service_name, assembly_template_name)
		puts "Create assembly template from assembly:", "---------------------------------------"
		template_created = false	
		create_assembly_template_response = send_request('/rest/assembly/create_new_template', {:service_module_name=>service_name, :assembly_id=>assembly_id, :assembly_template_name=>assembly_template_name})
		if (create_assembly_template_response['status'] == 'ok')
			puts "Assembly template #{assembly_template_name} created in service #{service_name}"
			template_created = true
		else
			puts "Assembly template #{assembly_template_name} was not created in service #{service_name}" 
			template_created = true
		end
		puts ""
		return template_created
	end

	def netstats_check(assembly_id, port)
		puts "Netstats check:", "---------------"
		sleep 20 #Before initiating netstats check, wait for services to be up
 		netstats_check = false
		response = send_request('/rest/assembly/initiate_get_netstats', {:node_id=>nil, :assembly_id=>assembly_id})
		action_results_id = response['data']['action_results_id']

		end_loop = false
		count = 0
		max_num_of_retries = 50

		while (end_loop == false)
			sleep 20
			count += 1
			response = send_request('/rest/assembly/get_action_results', {:disable_post_processing=>false, :return_only_if_complete=>true, :action_results_id=>action_results_id})
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

	def import_remote_module(module_to_import)
		puts "Import remote module:", "---------------------"
		module_imported = false
		modules_list = send_request('/rest/component_module/list', {})
		
		if (modules_list['data'].select { |x| x['display_name'] == module_to_import }.first)
			puts "Module #{module_to_import} already exists in module list."
			module_imported = false
		else
			puts "Module not found in module list. Checking if module exist on remote repo..."
			remote_modules_list = send_request('/rest/component_module/list_remote', {})

			if (remote_modules_list['data'].select { |x| x['display_name'].include? module_to_import}.first)
				puts "Module specified found in list of remote modules. Try to import module..."
				import_response = send_request('/rest/component_module/import', {:remote_module_name=>module_to_import, :local_module_name=>module_to_import})
				puts "Module import response:"
				pretty_print_JSON(import_response)
				modules_list = send_request('/rest/component_module/list', {})
				puts "List of avaliable modules:"
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
		puts ""
		return module_imported
	end

	def export_module_to_remote(module_to_export, namespace)
		puts "Export module to remote:", "------------------------"
		module_exported = false
		modules_list = send_request('/rest/component_module/list', {})

		if (modules_list['data'].select { |x| x['display_name'] == module_to_export }.first)
			puts "Module #{module_to_export} exists in module list. Check if module exists on remote repo already..."
			remote_modules_list = send_request('/rest/component_module/list_remote', {})
			pretty_print_JSON(remote_modules_list)

			if (remote_modules_list['data'].select { |x| x['display_name'].include? "#{namespace}/#{module_to_export}"}.first)
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
		puts ""
		return module_exported
	end

	def delete_module_from_remote(module_name, namespace)
		puts "Delete module from remote:", "--------------------------"
		module_deleted = false

		remote_modules_list = send_request('/rest/component_module/list_remote', {})
		puts "List of remote modules:"
		pretty_print_JSON(remote_modules_list)

		if (remote_modules_list['data'].select { |x| x['display_name'].include? "#{namespace}/#{module_name}" }.first)
			puts "Module #{module_name} in #{namespace} namespace exists. Proceed with deleting this module..."
			delete_remote_module = send_request('/rest/component_module/delete_remote', {:remote_module_name=>module_name, :remote_module_namespace=>namespace})
			if (delete_remote_module['status'] == 'ok')
				puts "Module #{module_name} in #{namespace} deleted from remote!"
				module_deleted = true
			else
				puts "Module #{module_name} in #{namespace} was not deleted from remote!"
				module_deleted = false				
			end
		else
			puts "Module #{module_name} in #{namespace} namespace does not exist!"
			module_deleted = false
		end
		puts ""
		return module_deleted
	end

	def get_module_components_list(module_name, filter_version)
		puts "Get module components list:", "---------------------------"
		component_ids_list = Array.new()
		modules_list = send_request('/rest/component_module/list', {})

		if (modules_list['data'].select { |x| x['display_name'] == module_name}.first)
			puts "Module #{module_name} exists in the list. Get component module id..."
			component_module_id = modules_list['data'].select { |x| x['display_name'] == module_name}.first['id']
			module_components_list = send_request('/rest/component_module/info_about', {:about=>"components", :component_module_id=>component_module_id})
			puts "List of module components:"
			pretty_print_JSON(module_components_list)

			module_components_list['data'].each do |x|
				if (filter_version != "")
					@component_module_id_list << x['id'] if x['version'] == filter_version
					puts "module component: #{x['display_name']}"
				else
					@component_module_id_list << x['id'] if x['version'] == nil
					puts "module component: #{x['display_name']}"
				end
			end
		end
		puts ""
	end

	def check_if_component_exists_in_module(module_name, filter_version, component_name)
		puts "Check if component exists in module:", "------------------------------------"
		component_exists_in_module = false
		component_names_list = Array.new()
		modules_list = send_request('/rest/component_module/list', {})

		if (modules_list['data'].select { |x| x['display_name'] == module_name}.first)
			puts "Module #{module_name} exists in the list. Get component module id..."
			component_module_id = modules_list['data'].select { |x| x['display_name'] == module_name}.first['id']
			module_components_list = send_request('/rest/component_module/info_about', {:about=>"components", :component_module_id=>component_module_id})
			puts "List of module components:"
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
			component_exists_in_module = true
		else
			puts "Component names list does not include #{component_name}"
		end
		puts ""
		return component_exists_in_module
	end

	def add_component_to_assembly_node(assembly_id, node_name, component_id)
		puts "Add component to assembly node:", "-------------------------------"
		component_added = false
		assembly_nodes = send_request('/rest/assembly/info_about', {:assembly_id=>assembly_id, :filter=>nil, :about=>'nodes', :subtype=>'instance'})

		if (assembly_nodes['data'].select { |x| x['display_name'] == node_name }.first)
			puts "Node #{node_name} exists in assembly. Get node id..."
			node_id = assembly_nodes['data'].select { |x| x['display_name'] == node_name }.first['id']
			component_add_response = send_request('/rest/assembly/add_component', {:node_id=>node_id, :component_template_id=>component_id, :assembly_id=>assembly_id})

			if (component_add_response['status'] == 'ok')
				puts "Component with id #{component_id} added to assembly!"
				component_added = true
			end
		end
		puts ""
		return component_added
	end

	def add_component_by_name_to_assembly_node(assembly_id, node_name, component_name)
		puts "Add component to assembly node:", "-------------------------------"
		component_added = false
		assembly_nodes = send_request('/rest/assembly/info_about', {:assembly_id=>assembly_id, :filter=>nil, :about=>'nodes', :subtype=>'instance'})

		if (assembly_nodes['data'].select { |x| x['display_name'] == node_name }.first)
			puts "Node #{node_name} exists in assembly. Get node id..."
			node_id = assembly_nodes['data'].select { |x| x['display_name'] == node_name }.first['id']
			component_add_response = send_request('/rest/assembly/add_component', {:node_id=>node_id, :component_template_id=>component_name, :assembly_id=>assembly_id})

			if (component_add_response['status'] == 'ok')
				puts "Component #{component_name} added to assembly!"
				component_added = true
			end
		end
		puts ""
		return component_added
	end

	def delete_module(module_to_delete)
		puts "Delete module:", "--------------"
		module_deleted = false
		modules_list = send_request('/rest/component_module/list', {})

		if (modules_list['data'].select { |x| x['display_name'] == module_to_delete }.first)
			puts "Module #{module_to_delete} exists in module list. Try to delete module..."
			delete_response = send_request('/rest/component_module/delete', {:component_module_id=>module_to_delete})
			puts "Module delete response:"
			pretty_print_JSON(delete_response)

			if (delete_response['status'] == 'ok' && modules_list['data'].select { |x| x['module_name'] == nil })
				puts "Module #{module_to_delete} deleted successfully"
				module_deleted = true
			else
				puts "Module #{module_to_delete} was not deleted successfully"
				module_deleted = false
			end
		else
			puts "Module #{module_to_delete} does not exist in module list and therefore cannot be deleted."
			module_deleted = false
		end
		puts ""
		return module_deleted
	end

	def create_new_module_version(module_name, version)
		puts "Create new module version:", "--------------------------"
		module_versioned = false
		modules_list = send_request('/rest/component_module/list', {})

		if (modules_list['data'].select { |x| x['display_name'] == module_name }.first)
			puts "Module #{module_name} exists in module list. Try to version module..."
			module_id = modules_list['data'].select { |x| x['display_name'] == module_name }.first['id']
			versioning_response = send_request('/rest/component_module/create_new_version', {:version=>version, :component_module_id=>module_id})
			puts "Versioning response:"
			pretty_print_JSON(versioning_response)
			puts "Module list response:"
			modules_list = send_request('/rest/component_module/list', {})
			pretty_print_JSON(modules_list)

			if (versioning_response['status'] == 'ok' && modules_list['data'].select { |x| (x['display_name'] == module_name) && (x['version'].include? version) }.first)
				puts "Module #{module_name} versioned successfully."
				module_versioned = true
			else
				puts "Module #{module_name} was not versioned successfully."
				module_versioned = false
			end
		else
			puts "Module #{module_name} does not exist in module list and therefore cannot be versioned."
			module_versioned = false
		end
		puts ""
		return module_versioned
	end

	def import_versioned_module_from_remote(module_name, version)
		puts "Import versioned module from remote:", "------------------------------------"
		module_imported = false
		modules_list = send_request('/rest/component_module/list', {})

		if (modules_list['data'].select { |x| x['display_name'] == module_name }.first)
			puts "Module #{module_name} exists in module list. Try to import versioned module..."
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
			puts "Module #{module_name} does not exist in module list and therefore versioned module cannot be imported."
			module_imported = false
		end
		puts ""
		return module_imported
	end

	def create_new_service(service_name)
		puts "Create new service:", "-------------------"
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
		puts ""
		return service_created
	end

	def check_if_service_exists_on_remote(service_name, namespace)
		puts "Check if service exists on remote:", "----------------------------------"
		service_exists = false
		service_remote_list = send_request('/rest/service_module/list_remote', {})
		puts "Service list on remote:"
		pretty_print_JSON(service_remote_list)

		if (service_remote_list['data'].select { |x| x['display_name'] == "#{namespace}/#{service_name}" }.first)
			puts "Service #{service_name} with namespace #{namespace} exists on remote repo!"
			service_exists = true
		else
			puts "Service #{service_name} with namespace #{namespace} does not exist on remote repo!"
		end
		puts ""
		return service_exists
	end

	def export_service_to_remote(service_name, namespace)
		puts "Export service to remote:", "-------------------------"
		service_exported = false
		service_list = send_request('/rest/service_module/list', {})

		if (service_list['data'].select { |x| x['display_name'] == service_name }.first)
			puts "Service #{service_name} exists in service list. Check if service exists on remote repo already..."
			service_remote_list = send_request('/rest/service_module/list_remote', {})

			if (service_remote_list['data'].select { |x| x['display_name'].include? service_name}.first)
   			puts "Service #{service_name} was found in list of remote services."
   			service_exported = false
			else
				puts "Service #{service_name} was not found in list of remote services. Proceed with export of service..."
				service_module_id = service_list['data'].select { |x| x['display_name'] == service_name}.first['id']				
				export_response = send_request('/rest/service_module/export', {:remote_component_name=>service_name, :service_module_id=>service_module_id, :remote_component_namespace=>namespace})

				puts "Service export response:"
				pretty_print_JSON(export_response)
				service_remote_list = send_request('/rest/service_module/list_remote', {})

				if (service_remote_list['data'].select { |x| x['display_name'].include? service_name}.first)
					puts "Service #{service_name} exported successfully in namespace #{namespace}"
					service_exported = true
				else
					puts "Service #{service_name} was not exported successfully in namespace #{namespace}"
					service_exported = false
				end			
			end
		else
			puts "Service #{service_name} not found in service list and therefore cannot be exported"
			service_exported = false
		end
		puts ""
		return service_exported
	end

	def delete_service(service_name)
		puts "Delete service:", "---------------"
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
			puts "Service #{service_name} does not exist in service list and therefore cannot be deleted."
			service_deleted = false
		end
		puts ""
		return service_deleted
	end

	def delete_service_from_remote(service_name, namespace)
		puts "Delete service from remote:", "---------------------------"
		service_deleted = false

		service_remote_list = send_request('/rest/service_module/list_remote', {})
		puts "List of remote services:"
		pretty_print_JSON(service_remote_list)

		if (service_remote_list['data'].select { |x| x['display_name'].include? "#{namespace}/#{service_name}" }.first)
			puts "Service #{service_name} in #{namespace} namespace exists. Proceed with deleting this service..."
			delete_remote_service = send_request('/rest/service_module/delete_remote', {:remote_service_name=>"#{namespace}/#{service_name}"})
			if (delete_remote_service['status'] == 'ok')
				puts "Service #{service_name} in #{namespace} deleted from remote!"
				service_deleted = true
			else
				puts "Service #{service_name} in #{namespace} was not deleted from remote!"
				service_deleted = false				
			end
		else
			puts "Service #{service_name} in #{namespace} namespace does not exist on remote!"
			service_deleted = false
		end
		puts ""
		return service_deleted
	end

	def check_if_service_contains_assembly_template(service_name, assembly_template_name)
		puts "Check if service contains assembly template:", "---------------"
		service_contains_template = false
		service_list = send_request('/rest/service_module/list', {})

		if (service_list['data'].select { |x| x['display_name'] == service_name }.first)
			puts "Service exists in service list. Try to find if #{assembly_template_name} belongs to #{service_name} service..."
			service_id = service_list['data'].select { |x| x['display_name'] == service_name }.first['id']
			service_templates_list = send_request('/rest/service_module/list_assemblies', {:service_module_id=>service_id})
			puts "List of assembly templates that belong to service #{service_name}:"
			pretty_print_JSON(service_templates_list)

			if (service_templates_list['data'].select { |x| x['display_name'] == assembly_template_name }.first)
				puts "Assembly template #{assembly_template_name} belongs to #{service_name} service."
				service_contains_template = true
			else
				puts "Assembly template #{assembly_template_name} does not belong to #{service_name} service."
				service_contains_template = false
			end
		else
			puts "Service #{service_name} does not exist in service list."
			service_contains_template = false
		end
		puts ""
		return service_contains_template
	end
end