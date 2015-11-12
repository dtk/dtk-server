module ServiceModulesVersionMixin

	def create_service_module_version(service_module_name, service_module_version)
  		puts 'Create service module version:', '--------------------------------'
  		service_module_version_created = false
  		service_modules_list = send_request('/rest/service_module/list', {})
  		if (service_modules_list['data'].select { |x| x['display_name'] == service_module_name }.first)
  			puts "Service module #{service_module_name} exists in list. Try to create service module version #{service_module_version}..."

  			create_version_response = send_request('/rest/service_module/create_new_version', {service_module_id: service_module_name, version: service_module_version})

	  		puts 'Service module create version response:'
  			puts '-----------------------------------------'
  			pretty_print_JSON(create_version_response)

	  		if (create_version_response['status'] == 'ok')
  				puts "Service module #{service_module_name} version #{service_module_version} created successfully"
				service_module_version_created = true
			else
				puts "Service module #{service_module_name} version #{service_module_version} was not created successfully"
				service_module_version_created = false
			end
		else
			puts "Service module #{service_module_name} does not exist in service module list and therefore cannot be versioned"
			service_module_version_created = false
	  	end
  		puts ''
  		service_module_version_created
  	end

 	def delete_service_module_version(service_module_name, service_module_version)
    	puts 'Delete service module version:', '--------------------------------'
    	service_module_version_deleted = false
    	service_modules_list = send_request('/rest/service_module/list', {})

    	if (service_modules_list['data'].select { |x| x['display_name'] == service_module_name }.first)
    		puts "Service module #{service_module_name} exists in list. Try to delete service module version #{service_module_version}..."

    		delete_version_resposne = send_request('/rest/service_module/delete', {service_module_id: service_module_name, version: service_module_version})

    		puts 'Service module delete version response:'
    		puts '-----------------------------------------'
    		pretty_print_JSON(delete_version_resposne)

    		if (delete_version_resposne['status'] == 'ok')
    			puts "Service module #{service_module_name} version #{service_module_version} deleted successfully"
				service_module_version_deleted = true
			else
				puts "Service module #{service_module_name} version #{service_module_version} was not deleted successfully"
				service_module_version_deleted = false
			end
		else
			puts "Service module #{service_module_name} does not exist in service module list and therefore service module version cannot be deleted"
			service_module_version_deleted = false
  		end

  		puts ''
  		service_module_version_deleted
    end

    def delete_remote_service_module_version(service_module_name, service_module_namespace, service_module_version)
    	puts "Delete service module version from remote:", "--------------------------------------------"
     	service_module_version_deleted = false
     	remote_service_modules_list = send_request('/rest/service_module/list_remote', {rsa_pub_key: self.ssh_key, diff: {}})

     	if (remote_service_modules_list['data'].select { |x| x['display_name'] == "#{service_module_namespace}/#{service_module_name}" }.first)
     		puts "Service module #{service_module_name} exists on remote. Try to delete service module version #{service_module_version}..."

    		delete_remote_version_resposne = send_request('/rest/service_module/delete_remote', {rsa_pub_key: self.ssh_key, remote_module_name: service_module_name, remote_module_namespace: service_module_namespace, force_delete: false, version: service_module_version})

 			if (delete_remote_version_resposne['status'] == 'ok')
    			puts "Service module #{service_module_name} version #{service_module_version} deleted successfully"
				service_module_version_deleted = true
			else
				puts "Service module #{service_module_name} version #{service_module_version} was not deleted successfully"
				service_module_version_deleted = false
			end
		else
			puts "Service module #{service_module_name} does not exist in service module list and therefore service module version cannot be deleted from remote"
			service_module_version_deleted = false
     	end

     	service_module_version_deleted
    end

    def clone_service_module_version(service_module_name, service_module_version)
    	puts "Clone service module version", "-----------------------------"
  		service_module_version_cloned = false

  		client = DtkClientAccessor.new
  		response = client.execute_command_with_options('component_module', 'component_module', '', 'ls', {}, [])
  		response = client.execute_command_with_options('service_module', 'service_module', service_module_name, 'clone', {version: service_module_version}, [])
  			
  		pretty_print_JSON(response)
  		service_module_version_cloned = true if response['status'] == 'ok'
    end

    def delete_all_service_module_versions(service_module_name)
    	puts 'Delete all service module versions:', '-------------------------------------'
    	service_module_versions_deleted = false
    	service_modules_list = send_request('/rest/service_module/list', {})

    	if (service_modules_list['data'].select { |x| x['display_name'] == service_module_name }.first)
    		puts "Service module #{service_module_name} exists in list. Try to delete service module versions..."

    		delete_versions_resposne = send_request('/rest/service_module/delete', {service_module_id: service_module_name, delete_all_versions: true})

    		puts 'Service module versions delete response:'
    		puts '-----------------------------------------'
    		pretty_print_JSON(delete_versions_resposne)

    		if (delete_versions_resposne['status'] == 'ok')
    			puts "Service module #{service_module_name} versions deleted successfully"
				service_module_versions_deleted = true
			else
				puts "Service module #{service_module_name} versions were not deleted successfully"
				service_module_versions_deleted = false
			end
		else
			puts "Service module #{service_module_name} does not exist in service module list and therefore service module versiona cannot be deleted"
			service_module_versions_deleted = false
  		end

  		puts ''
  		service_module_versions_deleted
    end  
end
