module NodeOperationsMixin
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

	def delete_component_from_service(service_id, node_name, component_to_delete)
		puts "Delete component from service node:", "-----------------------------------"
		component_deleted = false
		puts "List of service components:"
		service_components = send_request('/rest/assembly/info_about', {:assembly_id=>service_id, :filter=>nil, :about=>'components', :subtype=>'instance'})
		pretty_print_JSON(service_components)

		if node_name.nil?
			component = service_components['data'].select { |x| x['display_name'] == "#{component_to_delete}" }.first
		else
			component = service_components['data'].select { |x| x['display_name'] == "#{node_name}/#{component_to_delete}" }.first
		end

		if !component.nil?
			if !node_name.nil?
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
				puts "Deleting component #{component_to_delete} from service instance..."
				component_delete_response = send_request('/rest/assembly/delete_component', {:assembly_id=>service_id, :component_id=>component['id']})
				pretty_print_JSON(component_delete_response)
				if component_delete_response['status'].include? 'ok'
					puts "Component #{component_to_delete} has been deleted successfully!"
					component_deleted = true
				else
					puts "Component #{component_to_delete} has not been deleted successfully!"
				end
			end
		else
			puts "Component #{component_to_delete} does not exist on #{node_name} and therefore cannot be deleted!"
		end
		puts ""
		return component_deleted
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
			pretty_print_JSON(response)
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

	def add_component_to_service_node(service_id, node_name, component_id, namespace)
		puts "Add component to node:", "----------------------"
		component_added = false

		node_list = send_request('/rest/assembly/info_about', {:assembly_id=>service_id, :subtype=>'instance', :about=>'nodes'})
		puts "Node list:"
		pretty_print_JSON(node_list)
		node_id = node_list['data'].select { |x| x['display_name'] == node_name }.first['id']
		component_add_response = send_request('/rest/assembly/add_component', {:assembly_id=>service_id, :node_id=>node_id, :component_template_id=>component_id, :namespace=>namespace})

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
					puts "Error details on subtasks:"
					ap response_task_status['data']['subtasks']
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

	def netstats_check_for_specific_node(service_id, node_name, port)
		puts "Netstats check:", "---------------"

		node_list = send_request('/rest/assembly/info_about', {:assembly_id=>service_id, :subtype=>'instance', :about=>'nodes'})
		pretty_print_JSON(node_list)
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