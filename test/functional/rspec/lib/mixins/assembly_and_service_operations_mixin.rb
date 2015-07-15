module AssemblyAndServiceOperationsMixin
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

	def stage_service_with_namespace(namespace)
		#Get list of assemblies, extract selected assembly, stage service and return its id
		puts "Stage service:", "--------------"
		service_id = nil
		extract_id_regex = /id: (\d+)/
		assembly_list = send_request('/rest/assembly/list', {:subtype=>'template'})
 
		puts "List of avaliable assemblies: "
		pretty_print_JSON(assembly_list)
		test_template = assembly_list['data'].select { |x| x['display_name'] == @assembly && x['namespace'] == namespace }.first

		if (!test_template.nil?)
			puts "Assembly #{@assembly} from namespace #{namespace} found!"
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

	def list_specific_success_service(service_name)
		puts "List success services:", "------------------------"
		service_list = send_request('/rest/assembly/list', {:subtype=>'instance', :detail_level => 'nodes'})
		success_services = service_list['data'].select { |x| x['display_name'] == service_name && x['execution_status'] == 'succeeded' }
		pretty_print_JSON(success_services)
		return success_services
	end

	def list_specific_failed_service(service_name)
		puts "List failed services:", "-------------------------"
		service_list = send_request('/rest/assembly/list', {:subtype=>'instance', :detail_level => 'nodes'})
		failed_services = service_list['data'].select { |x| x['display_name'] == service_name && x['execution_status'] == 'failed' }
		pretty_print_JSON(failed_services)
		return failed_services
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
		service_attributes = send_request('/rest/assembly/info_about', {:about=>'attributes', :filter=>nil, :subtype=>'instance', :assembly_id=>service_id})
		attribute_id = service_attributes['data'].select { |x| x['display_name'].include? attribute_name }.first['id']

		#Set attribute value for given attribute id
		set_attribute_value_response = send_request('/rest/assembly/set_attributes', {:assembly_id=>service_id, :value=>attribute_value, :pattern=>attribute_id})
		service_attributes = send_request('/rest/assembly/info_about', {:about=>'attributes', :filter=>nil, :subtype=>'instance', :assembly_id=>service_id})
		extract_attribute_value = attribute_id = service_attributes['data'].select { |x| x['display_name'].include? attribute_name }.first['value']

		if (extract_attribute_value == attribute_value)
			puts "Setting of attribute #{attribute_name} completed successfully!"
			is_attributes_set = true
		end
		puts ""
		return is_attributes_set
	end

	def set_attribute_on_service_level_component(service_id, attribute_name, attribute_value)
		#Set attribute on particular service
		puts "Set attribute:", "--------------"
		is_attributes_set = false

		#Get attribute id for which value will be set
		service_attributes = send_request('/rest/assembly/info_about', {:about=>'attributes', :filter=>nil, :subtype=>'instance', :assembly_id=>service_id})
		attribute_id = service_attributes['data'].select { |x| x['display_name'].include? attribute_name }.first['id']

		#Set attribute value for given attribute id
		set_attribute_value_response = send_request('/rest/assembly/set_attributes', {:assembly_id=>service_id, :value=>attribute_value, :pattern=>attribute_id})
		service_attributes = send_request('/rest/assembly/info_about', {:about=>'attributes', :filter=>nil, :subtype=>'instance', :assembly_id=>service_id})
		extract_attribute_value = attribute_id = service_attributes['data'].select { |x| x['display_name'].include? attribute_name }.first['value']

		if (extract_attribute_value == attribute_value)
			puts "Setting of attribute #{attribute_name} completed successfully!"
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

	def converge_service(service_id, max_num_of_retries=15)
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
				response_task_status = send_request('/rest/assembly/task_status', {'assembly_id'=> service_id})
				status = response_task_status['data'].first['status']
				unless status.nil?
					if (status.include? 'succeeded')
						service_converged = true
						puts "Task execution status: #{status}"
						puts "Converge process finished successfully!"
					elsif (status.include? 'failed')
						puts "Error details on subtasks:"
						puts "Task execution status: #{status}"
						puts "Converge process was not finished successfully! Some tasks failed!"
						end_loop = true
					end
					puts "Task execution status: #{status}"
				end

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

	def create_assembly_from_service(service_id, service_module_name, assembly_name, namespace=nil)
		puts "Create assembly from service:", "-----------------------------"
		assembly_created = false
		create_assembly_response = send_request('/rest/assembly/promote_to_template', {:service_module_name=>service_module_name, :assembly_id=>service_id, :assembly_template_name=>assembly_name, :namespace=>namespace})
		if (create_assembly_response['status'] == 'ok')
			puts "Assembly #{assembly_name} created in service module #{service_module_name}"
			assembly_created = true
		else
			puts "Assembly #{assembly_name} was not created in service module #{service_module_name}" 
		end
		puts ""
		return assembly_created
	end

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
			pretty_print_JSON(response)
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

	def add_component_by_name_to_service_node(service_id, node_name, component_name)
		puts "Add component to service:", "--------------------------"
		component_added = false
		service_nodes = send_request('/rest/assembly/info_about', {:assembly_id=>service_id, :filter=>nil, :about=>'nodes', :subtype=>'instance'})

		if (service_nodes['data'].select { |x| x['display_name'] == node_name }.first)
			puts "Node #{node_name} exists in service. Get node id..."
			node_id = service_nodes['data'].select { |x| x['display_name'] == node_name }.first['id']
			component_add_response = send_request('/rest/assembly/add_component', {:node_id=>node_id, :component_template_id=>component_name.split(":").last, :assembly_id=>service_id, :namespace=>component_name.split(":").first})

			if (component_add_response['status'] == 'ok')
				puts "Component #{component_name} added to service!"
				component_added = true
			end
		else
			component_add_response = send_request('/rest/assembly/add_component', {:node_id=>nil, :component_template_id=>component_name.split(":").last, :assembly_id=>service_id, :namespace=>component_name.split(":").first})

			if (component_add_response['status'] == 'ok')
				puts "Component #{component_name} added to service!"
				component_added = true
			end
		end
		puts ""
		return component_added
	end

	def delete_and_destroy_service(service_id)
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

	def push_assembly_updates(service_id, service_module)
		puts "Push assembly updates:", "---------------------"
		assembly_updated = false
		response = send_request('/rest/assembly/promote_to_template', {:assembly_id=>service_id, :mode => 'update', :use_module_namespace => true })
		pretty_print_JSON(response)
		if response['status'] == 'ok' && response['data']['full_module_name'] == service_module
			assembly_updated = true
		end
		puts ""
		return assembly_updated
	end

	def push_component_module_updates_without_changes(service_id, component_module)
		puts "Push component module updates:", "-------------------------------"
		response = send_request('/rest/assembly/promote_module_updates', {:assembly_id=>service_id, :module_name => component_module, :module_type => "component_module" })
		return response
	end

	def get_nodes(service_id)
		puts "Get all nodes from service:", "-----------------------------"
		nodes_list = send_request('/rest/assembly/info_about', {:assembly_id=>service_id, :node_id => nil, :component_id => nil, :subtype=>'instance', :about=>'nodes'})
		nodes_list = nodes_list['data'].map! { |c| c['display_name'] }
		pretty_print_JSON(nodes_list)
		puts ""
		return nodes_list
	end

	def get_components(service_id)
		puts "Get all components from service:", "-----------------------------"
		components_list = send_request('/rest/assembly/info_about', {:assembly_id=>service_id, :node_id => nil, :component_id => nil, :subtype=>'instance', :about=>'components'})
		components_list = components_list['data'].map! { |c| c['display_name'] }
		puts ""
		return components_list
	end

	def get_cardinality(service_id, node_name)
		puts "Get cardinality from service:", "-----------------------------"
		cardinality = send_request('/rest/assembly/info_about', {:assembly_id=>service_id, :node_id => nil, :component_id => nil, :subtype=>'instance', :about=>'attributes', :format=>'yaml'})
		content = YAML.load(cardinality['data'])
		puts content
    attributes = (content["nodes"]["#{node_name}/"]||{})['attributes']||{}
    puts ""
		return attributes['cardinality'] && attributes['cardinality'].to_i
	end

	def get_workflow_info(service_id)
		puts "Get workflow info:", "----------------------"
		workflow_info = send_request('/rest/assembly/info_about_task', {:assembly_id=>service_id, :subtype => 'instance'})
		content = YAML.load(workflow_info['data'])
		puts content
		puts ""
		return content
	end

	def grant_access(service_id, system_user, rsa_pub_name, ssh_key)
		puts "Grant access:", "-----------------"
		response = send_request('/rest/assembly/initiate_ssh_pub_access', {:agent_action => :grant_access, :assembly_id=>service_id, :system_user => system_user, :rsa_pub_name => rsa_pub_name, :rsa_pub_key => ssh_key})
		pretty_print_JSON(response)
		puts ""
		return response
	end

	def revoke_access(service_id, system_user, rsa_pub_name, ssh_key)
		puts "Revoke access:", "-----------------"
		resp = send_request('/rest/assembly/initiate_ssh_pub_access', {:agent_action => :revoke_access, :assembly_id=>service_id, :system_user => system_user, :rsa_pub_name => rsa_pub_name, :rsa_pub_key => ssh_key})
		pretty_print_JSON(resp)
		response = send_request('/rest/assembly/get_action_results', {:action_results_id => resp['data']['action_results_id'], :return_only_if_complete => true, :disable_post_processing => true})
		puts response
		puts ""
		return response
	end

	def list_ssh_access(service_id, system_user, rsa_pub_name, nodes)
		puts "List ssh access:", "---------------------"
		sleep 5
		response = send_request('/rest/assembly/list_ssh_access', {:assembly_id=>service_id})
		pretty_print_JSON(response)
		list = response['data'].select { |x| x['attributes']['linux_user'] == system_user && x['attributes']['key_name'] == rsa_pub_name && (nodes.include? x['node_name']) }
		puts ""
		return list.map! { |x| x['attributes']['key_name']}
	end

	def get_task_action_output(service_id, action_id)
		puts "Get task action output:", "------------------------"
		response = send_request('/rest/assembly/task_action_detail', {:assembly_id=>service_id, :message_id=>action_id})
		pretty_print_JSON(response)
		runs = {}
		if response['status'] == "ok"
			output = response['data']
			output.gsub!("=","") if response['data'].include? "="
			runs = output.split(/\n \n\n|\n\n\n|\n\n/)
		else
			puts "Task action details were not retrieved successfully!"
		end
		puts ""
		return runs
	end

	def verify_flags(service_id, component_module_name, update_flag, update_saved_flag)
		puts "Verify update and update saved flags:", "---------------------------------"
		flags_verified = false
		response = send_request('/rest/assembly/info_about', {:assembly_id=>service_id, :subtype=>:instance, :about=>'modules', :detail_to_include=>[:version_info]})
		pretty_print_JSON(response)
		component_module_details = response['data'].select { |x| x['display_name'] == component_module_name }.first
		if !component_module_details.nil?
			puts "Component module found! Check flags..."
			pretty_print_JSON(component_module_details)
			unless component_module_details.key?('local_copy') || component_module_details.key?('update_saved')
				puts "Flags dont not exist in the output"
			end
			if component_module_details['local_copy'] == update_flag && component_module_details['update_saved'] == update_saved_flag
				puts "Update and update saved flags match the comparison"
				flags_verified = true
			else
				puts "Update and update saved flags does not match the comparison"
			end
		else
			puts "Component module was not found!"
		end
		puts ""
		flags_verified
	end
end