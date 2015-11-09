module ComponentModulesVersionMixin
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
    		puts "Component modue #{component_module_name} exists in list. Try to delete component module version #{component_module_version}..."

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
end