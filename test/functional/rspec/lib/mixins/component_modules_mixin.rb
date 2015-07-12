module ComponentModulesMixin
	def pull_base_component_module(service_id, component_module_name)
		puts "Pull base component module:", "-----------------------------"
		changes_pulled = false
		client = DtkClientAccessor.new
		response = client.execute_command('service', 'service', service_id, [component_module_name], 'pull_base_component_module')
		changes_pulled = true if response['status'] == 'ok'
	end

	def push_component_module_updates(service_id, component_module_name)
		puts "Push component module updates:", "---------------------------------"
		changes_pushed = false
		client = DtkClientAccessor.new
		response = client.execute_command('service', 'service', service_id, [component_module_name], 'push_component_module_updates')
		changes_pushed = true if response['status'] == 'ok'
	end

	def delete_module_from_remote(component_module, namespace)
		puts "Delete component module from remote:", "----------------------------------"
		component_module_deleted = false
		response = send_request('/rest/component_module/delete_remote', {:remote_module_name => component_module, :remote_module_namespace => namespace, :rsa_pub_key => self.ssh_key})

		if response['status'] == 'ok'
			puts "Component module #{component_module} has been deleted from remote successfully!"
			component_module_deleted = true
		else
			pretty_print_JSON(response)
			puts "Unable to delete component module #{component_module} from remote"
		end
		puts ""
		return component_module_deleted
	end

	def make_component_module_private(component_module)
		puts "Make component module private:", "------------------------------"
		component_module_private = false
		response = send_request('/rest/component_module/remote_chmod', {:module_id => component_module, :permission_selector => "o-rwd", :rsa_pub_key => self.ssh_key, :remote_module_namespace => nil})
		if response['status'] == 'ok'
			puts "Component module #{component_module} is now private"
			component_module_private = true
		else
			pretty_print_JSON(response)
			puts "Unable to set component module #{component_module} as private"
		end
		puts ""
		return component_module_private
	end

	def make_component_module_public(component_module)
		puts "Make component module public:", "-----------------------------"
		component_module_public = false
		response = send_request('/rest/component_module/remote_chmod', {:module_id => component_module, :permission_selector => "o+r", :rsa_pub_key => self.ssh_key, :remote_module_namespace => nil})
		if response['status'] == 'ok'
			puts "Component module #{component_module} is now public"
			component_module_public = true
		else
			pretty_print_JSON(response)
			puts "Unable to set component module #{component_module} as public"
		end
		puts ""
		return component_module_public
	end

	def set_chmod_for_component_module(component_module, permission_set)
		puts "Set chmod for component module:", "-------------------------------"
		chmod_set = false
		response = send_request('/rest/component_module/remote_chmod', {:module_id => component_module, :permission_selector => permission_set, :rsa_pub_key => self.ssh_key, :remote_module_namespace => nil})
		if response['status'] == 'ok'
			puts "Chmod #{permission_set} has been set for component module #{component_module} successfully"
			chmod_set = true
		else
			pretty_print_JSON(response)
			puts "Unable to set chmod #{permission_set} for component module #{component_module}"
		end
		puts ""
		return chmod_set
	end

	def add_collaborators(component_module, collaborators, collaborator_type)
		puts "Add collaborators to component module:", "-------------------------------------"
		collaborators_added = false

		if collaborator_type == "groups"
			response = send_request('/rest/component_module/remote_collaboration', {:module_id => component_module, :users => nil, :groups => collaborators, :action => :add, :remote_module_namespace => nil, :rsa_pub_key => self.ssh_key})			
			pretty_print_JSON(response)
			if response['status'] == 'ok'
				puts "Collaborators #{collaborators} have been added to component module #{component_module} successfully"
				collaborators_added = true
			else
				pretty_print_JSON(response)
				puts "Unable to add collaborators #{collaborators} to component_module #{component_module}"
			end
		end

		if collaborator_type == "users"
			response = send_request('/rest/component_module/remote_collaboration', {:module_id => component_module, :users => collaborators, :groups => nil, :action => :add, :remote_module_namespace => nil, :rsa_pub_key => self.ssh_key})			
			pretty_print_JSON(response)
			if response['status'] == 'ok'
				puts "Collaborators #{collaborators} have been added to component module #{component_module} successfully"
				collaborators_added = true
			else
				pretty_print_JSON(response)
				puts "Unable to add collaborators #{collaborators} to component_module #{component_module}"
			end
		end
		puts ""
		return collaborators_added
	end

	def remove_collaborators(component_module, collaborators, collaborator_type)
		puts "Remove collaborators to component module:", "----------------------------------------"
		collaborators_removed = false

		if collaborator_type == "groups"
			response = send_request('/rest/component_module/remote_collaboration', {:module_id => component_module, :users => nil, :groups => collaborators, :action => :remove, :remote_module_namespace => nil, :rsa_pub_key => self.ssh_key})			
			pretty_print_JSON(response)
			if response['status'] == 'ok'
				puts "Collaborators #{collaborators} have been removed from component module #{component_module} successfully"
				collaborators_removed = true
			else
				pretty_print_JSON(response)
				puts "Unable to remove collaborators #{collaborators} from component_module #{component_module}"
			end
		end

		if collaborator_type == "users"
			response = send_request('/rest/component_module/remote_collaboration', {:module_id => component_module, :users => collaborators, :groups => nil, :action => :remove, :remote_module_namespace => nil, :rsa_pub_key => self.ssh_key})			
			pretty_print_JSON(response)
			if response['status'] == 'ok'
				puts "Collaborators #{collaborators} have been removed from component module #{component_module} successfully"
				collaborators_removed = true
			else
				pretty_print_JSON(response)
				puts "Unable to remove collaborators #{collaborators} from component_module #{component_module}"
			end
		end
		puts ""
		return collaborators_removed
	end

	def check_collaborators(component_module, collaborators, collaborator_type, filter)
		puts "Check collaborators on component module:", "----------------------------------------"
		collaborators_exist = true

		response = send_request('/rest/component_module/list_remote_collaboration', {:module_id => component_module, :remote_module_namespace => nil, :rsa_pub_key => self.ssh_key})		
		pretty_print_JSON(response)

		if filter == :name
			collaborators.each do |c|
				collaborators_exist = false if response['data'].select { |x| (x['owner_name'] == c) && (x['owner_type'] == collaborator_type)}.empty?
			end
		end

		if filter == :email
			collaborators.each do |c|
				collaborators_exist = false if response['data'].select { |x| (x['owner_email'] == c) && (x['owner_type'] == collaborator_type)}.empty?
			end
		end
		
		puts "All collaborators exists in list of collaborators" if collaborators_exist == true
		puts "All collaborators does not exist in list of collaborators" if collaborators_exist == false
		puts ""
		return collaborators_exist
	end

	def check_if_component_module_visible_on_remote(component_module)
		puts "Check if component module is visible on remote:", "--------------------------------------------"
		component_module_visible = false
		response = send_request('/rest/component_module/list_remote', {:rsa_pub_key => self.ssh_key, :diff => {}})
		pretty_print_JSON(response)
		component_module_found = response['data'].select { |x| x['display_name'] == component_module }
		unless component_module_found.empty?
			puts "Component module #{component_module} is visible"
			component_module_visible = true
		else
			puts "Component module #{component_module} is not visible"
		end
		puts ""
		return component_module_visible
	end

	def check_module_permissions(component_module, permissions_set)
		puts "Check module permissions:", "-------------------------"
		module_permissions_set = false
		response = send_request('/rest/component_module/list_remote', {:rsa_pub_key => self.ssh_key, :diff => {}})
		component_module_found = response['data'].select { |x| x['display_name'] == component_module }.first
		unless component_module_found.nil?
			puts "Component module #{component_module} exists. Check module permissions..."
			pretty_print_JSON(component_module_found)
			if permissions_set == component_module_found['permissions']
				puts "Permissions #{permissions_set} exist on component module #{component_module}"
				module_permissions_set = true
			else
				puts "Permissions #{permissions_set} dont exist on component module #{component_module}"
			end
		else
			puts "Component module #{component_module} does not exist or it is not visible"
		end
		puts ""
		return module_permissions_set
	end

	def check_if_component_module_exists(component_module_name)
		puts "Check if component module exists:", "---------------------------------"
		component_module_exists = false
		component_modules_list = send_request('/rest/component_module/list', {})

		if (component_modules_list['data'].select { |x| x['display_name'] == component_module_name }.first)
			puts "Component module #{component_module_name} exists in module list."
			component_module_exists = true
		else
			puts "Component module #{component_module_name} does not exist in module list"
		end
		puts ""
		return component_module_exists
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
					@component_module_name_list << x['display_name'] if x['version'] == filter_version
					puts "Component module component: #{x['display_name']}"
				else
					@component_module_id_list << x['id'] if x['version'] == nil
					@component_module_name_list << x['display_name'] if x['version'] == nil
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
			attribute_value = component_module_attribute_list['data'].select { |x| x['display_name'] == "cmp[#{component_module_name.split(":").last}::#{component_name}]/#{attribute_name}" }.first['value']
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

	def list_component_modules_with_filter(namespace)
		puts "List component modules with filter:", "---------------------------------"
		component_modules_retrieved = true
		component_modules_list = send_request('/rest/component_module/list', {:detail_to_include => [], :module_namespace => namespace})		
		pretty_print_JSON(component_modules_list)

		if component_modules_list['data'].empty?
			component_modules_retrieved = false
		else
			component_modules_list['data'].each do |cmp|
				if cmp['namespace']['display_name'] != namespace
					component_modules_retrieved = false
					break
				end
			end
		end
		puts ""
		return component_modules_retrieved
	end

	def list_remote_component_modules_with_filter(namespace)
		puts "List remote component modules with filter:", "------------------------------------"
		component_modules_retrieved = true
		component_modules_list = send_request('/rest/component_module/list_remote', {:rsa_pub_key => self.ssh_key, :module_namespace => namespace})		
		pretty_print_JSON(component_modules_list)

		if component_modules_list['data'].empty?
			component_modules_retrieved = false
		else
			component_modules_list['data'].each do |cmp|
				unless cmp['display_name'].include? namespace
					component_modules_retrieved = false
					break
				end
			end
		end
		puts ""
		return component_modules_retrieved
	end

	def check_if_remote_exists(component_module, provider_name, ssh_repo_url)
		puts "Check if remote exists:", "---------------------------"
		remote_exists = false
		remotes_list = send_request('/rest/component_module/info_git_remote', {:component_module_id => component_module})
		pretty_print_JSON(remotes_list)
		found_remote = remotes_list['data'].find { |x| x['git_provider'] == provider_name && x['repo_url'] == ssh_repo_url }
		if !found_remote.nil?
			puts "Remote #{provider_name} has been found for component module #{component_module} with repo url #{ssh_repo_url}"
			remote_exists = true
		else
			puts "Remote #{provider_name} has not been found for component module #{component_module} with repo url #{ssh_repo_url}"
		end
		puts ""
		return remote_exists
	end

	def add_remote(component_module, provider_name, url)
		puts "Add remote:", "------------"
		remote_added = false
		response = send_request('/rest/component_module/add_git_remote', {:component_module_id => component_module, :remote_name => provider_name, :remote_url => url})
		pretty_print_JSON(response)
		if response['status'] == 'ok'
			puts "Remote #{provider_name} with url #{url} has been added to #{component_module} component module successfully"
			remote_added = true
		else
			puts "Remote #{provider_name} with url #{url} has not been added to #{component_module} component module successfully"
		end
		puts ""
		return remote_added
	end

	def remove_remote(component_module, provider_name)
		puts "Remove remote:", "----------------"
		remote_removed = false
		remotes_list = send_request('/rest/component_module/info_git_remote', {:component_module_id => component_module})
		pretty_print_JSON(remotes_list)
		response = send_request('/rest/component_module/remove_git_remote', {:component_module_id => component_module, :remote_name => provider_name})
		pretty_print_JSON(response)
		if response['status'] == 'ok'
			puts "Remote #{provider_name} has been deleted from #{component_module} component module successfully"
			remote_removed = true
		else
			puts "Remote #{provider_name} has not been deleted from #{component_module} component module successfully"
		end
		puts ""
		return remote_removed
	end
end