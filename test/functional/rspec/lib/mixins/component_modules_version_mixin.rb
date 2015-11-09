module ComponentModulesVersionMixin

	def check_component_module_version(component_module_name, version_name)
		puts "List component module versions: ", "----------------------------------"
		version_found = false
		versions = send_request('/rest/component_module/list_versions', {:component_module_id => component_module_name})
		ap versions
		if versions['data'][0]['versions'].include? version_name
			puts "Version #{version_name} exists on component module #{component_module_name}"
			version_found = true
		else
			puts "Version #{version_name} does not exist on component module #{component_module_name}"
		end
		puts ""
		version_found
	end

	def check_component_module_remote_versions(component_module_name, version_name)
		puts "List remote component module versions: ", "-------------------------------------"
		remote_version_found = false
		remote_versions = send_request('/rest/component_module/list_remote_versions', {:component_module_id=>component_module_name, :rsa_pub_key => @ssh_key})
		ap remote_versions
		if remote_versions['data'][0]['versions'].include? version_name
		  puts "Version #{version_name} exists on component module #{component_module_name} remote"
			version_found = true
		else
      	puts "Version #{version_name} does not exist on component module #{component_module_name} remote"
		end
		puts ""
		remote_version_found
	end

	def set_attribute_on_versioned_component(component_module_name, component_name, attribute_name, attribute_value, version_name)
		puts "Set attribute on versioned component: ", "-------------------------------------"
		attribute_set = false
		list_attributes = send_request('/rest/component_module/info_about', {:about=>"attributes", :component_module_id=>component_module_name})
		ap list_attributes['data']
		list_attributes['data'].each do |attribute|
			if attribute['display_name'] == "cmp[#{component_name}(#{version_name})]/#{attribute_name}"
				puts "Attribute #{attribute_name} found. Set attribute value..."
				attribute_id = attribute['id']
				set_attribute_response = send_request('/rest/attribute/set', {:attribute_id=>attribute_id, :attribute_value=>attribute_value, :attribute_type=>"component_module", :component_module_id=>component_module_name})
				if set_attribute_response['status'] == 'ok'
					puts "Attribute cmp[#{component_name}(#{version_name})]/#{attribute_name} has value #{attribute_value} set"
					attribute_set = true
				else
					puts "Attribute cmp[#{component_name}(#{version_name})]/#{attribute_name} does not have value #{attribute_value} set"
				end
			end
		end
		puts ""
		attribute_set
	end

	def add_versioned_component_to_service(namespace, component_name, version_name, service_name, node_name)
		puts "Add versioned component to service:", "-----------------------------------"
		component_added_to_service = false
		response = send_request('/rest/assembly/add_component', {:assembly_id=>service_name, :node_id=>node_name, :component_template_id=>component_name + "(#{version_name})", :namespace=>namespace })
		ap response
		if response['status'] == 'ok'
			puts "Component #{component_name} with version #{version_name} added to service #{service_name} successfully!"
			component_added_to_service = true
		else
			puts "Component #{component_name} with version #{version_name} has not been added to service #{service_name} successfully!"
		end
		puts ""
		component_added_to_service
	end

	def publish_component_module_version(component_module_name, version_name)
		puts "Publish component module version: ", "-----------------------------------"
		module_published = false
		publish_response = send_request('/rest/component_module/export', {:component_module_id=>component_module_name, :rsa_pub_key=>ssh_key, :version=>version_name})
		ap publish_response
		if publish_response['status'] == 'ok' && publish_response['data']['remote_repo_name'] == component_module_name.split(":").last
			puts "Component module #{component_module_name} has been published successfully!"
			module_published = true
		else
			puts "Component module #{component_module_name} has not been published successfully!"
		end
		puts ""
		module_published
	end

  	def create_component_module_version(component_module_name, component_module_version)
  		puts 'Create component module version:', '--------------------------------'
  		component_module_version_created = false
  		component_modules_list = send_request('/rest/component_module/list', {})
  		if (component_modules_list['data'].select { |x| x['display_name'] == component_module_name }.first)
  			puts "Component modue #{component_module_name} exists in list. Try to create component module version #{component_module_version}..."

  			create_version_response = send_request('/rest/component_module/create_new_version', {component_module_id: component_module_name, version: component_module_version})

	  		puts 'Component module create version response:'
  			puts '-----------------------------------------'
  			pretty_print_JSON(create_version_response)

	  		if (create_version_response['status'] == 'ok')
  				puts "Component module #{component_module_name} version #{component_module_version} created successfully"
				component_module_version_created = true
			else
				puts "Component module #{component_module_name} version #{component_module_version} was not created successfully"
				component_module_version_created = false
			end
		else
			puts "Component module #{component_module_name} does not exist in component module list and therefore cannot be versioned"
			component_module_version_created = false
	  	end
  		puts ''
  		component_module_version_created
  	end


 	def delete_component_module_version(component_module_name, component_module_version)
    	puts 'Delete component module version:', '--------------------------------'
    	component_module_version_deleted = false
    	component_modules_list = send_request('/rest/component_module/list', {})

    	if (component_modules_list['data'].select { |x| x['display_name'] == component_module_name }.first)
    		puts "Component module #{component_module_name} exists in list. Try to delete component module version #{component_module_version}..."

    		delete_version_resposne = send_request('/rest/component_module/delete', {component_module_id: component_module_name, version: component_module_version})

    		puts 'Component module delete version response:'
    		puts '-----------------------------------------'
    		pretty_print_JSON(delete_version_resposne)

    		if (delete_version_resposne['status'] == 'ok')
    			puts "Component module #{component_module_name} version #{component_module_version} deleted successfully"
				component_module_version_deleted = true
			else
				puts "Component module #{component_module_name} version #{component_module_version} was not deleted successfully"
				component_module_version_deleted = false
			end
		else
			puts "Component module #{component_module_name} does not exist in component module list and therefore component module version cannot be deleted"
			component_module_version_deleted = false
  		end

  		puts ''
  		component_module_version_deleted
    end

    def delete_remote_component_module_version(component_module_name, component_module_namespace, component_module_version)
    	puts "Delete component module version from remote:", "--------------------------------------------"
     	component_module_version_deleted = false
     	remote_component_modules_list = send_request('/rest/component_module/list_remote', {rsa_pub_key: self.ssh_key, diff: {}})

     	if (remote_component_modules_list['data'].select { |x| x['display_name'] == "#{component_module_namespace}/#{component_module_name}" }.first)
     		puts "Component module #{component_module_name} exists on remote. Try to delete component module version #{component_module_version}..."

    		delete_remote_version_resposne = send_request('/rest/component_module/delete_remote', {rsa_pub_key: self.ssh_key, remote_module_name: component_module_name, remote_module_namespace: component_module_namespace, force_delete: false, version: component_module_version})
 			
 			if (delete_remote_version_resposne['status'] == 'ok')
    			puts "Component module #{component_module_name} version #{component_module_version} deleted successfully"
				component_module_version_deleted = true
			else
				puts "Component module #{component_module_name} version #{component_module_version} was not deleted successfully"
				component_module_version_deleted = false
			end
		else
			puts "Component module #{component_module_name} does not exist in component module list and therefore component module version cannot be deleted from remote"
			component_module_version_deleted = false
     	end
    end

    def clone_component_module_version(component_module_name, component_module_version)
    	puts "Clone component module version", "-----------------------------"
		component_module_version_cloned = false

		client = DtkClientAccessor.new
		response = client.execute_command_with_options('component_module', 'component_module', component_module_name, 'clone', {version: component_module_version}, [])
		
		pretty_print_JSON(response)
		component_module_version_cloned = true if response['status'] == 'ok'
    end
end