module ServiceModulesMixin
  def check_if_service_module_exists(service_module_name)
    puts 'Check if service module exists:', '-------------------------------'
    service_module_exists = false
    service_module_list = send_request('/rest/service_module/list', {})

    if (service_module_list['data'].find { |x| x['display_name'] == service_module_name })
      puts "Service #{service_module_name} exists."
      service_module_exists = true
    else
      puts "Service #{service_module_name} does not exist!"
    end
    puts ''
    return service_module_exists
  end

  def check_if_service_module_exists_on_remote(service_module_name, namespace)
    puts 'Check if service module exists on remote:', '-----------------------------------------'
    service_module_exists = false
    service_remote_list = send_request('/rest/service_module/list_remote', {})
    puts 'Service module list on remote:'
    pretty_print_JSON(service_remote_list)

    if (service_remote_list['data'].find { |x| x['display_name'] == "#{namespace}/#{service_module_name}" })
      puts "Service module #{service_module_name} with namespace #{namespace} exists on remote repo!"
      service_module_exists = true
    else
      puts "Service module #{service_module_name} with namespace #{namespace} does not exist on remote repo!"
    end
    puts ''
    return service_module_exists
  end

  def delete_service_module(service_module_name)
    puts 'Delete service module:', '----------------------'
    service_module_deleted = false
    service_module_list = send_request('/rest/service_module/list', {})

    if (service_module_list['data'].find { |x| x['display_name'] == service_module_name })
      puts "Service module exists in service module list. Try to delete service module #{service_module_name}..."
      delete_service_module_response = send_request('/rest/service_module/delete', service_module_id: service_module_name)
      puts 'Service module delete response:'
      pretty_print_JSON(delete_service_module_response)

      service_module_list = send_request('/rest/service_module/list', {})
      puts 'Service module list response:'
      pretty_print_JSON(service_module_list)

      if (delete_service_module_response['status'] == 'ok' && !service_module_list['data'].find { |x| x['display_name'] == service_module_name })
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
    puts ''
    return service_module_deleted
  end

  def delete_service_module_from_remote(service_module_name, namespace)
    puts 'Delete service module from remote:', '----------------------------------'
    service_module_deleted = false

    service_module_remote_list = send_request('/rest/service_module/list_remote', {})
    puts 'List of remote service module:'
    pretty_print_JSON(service_module_remote_list)

    if (service_module_remote_list['data'].find { |x| x['display_name'].include? "#{namespace}/#{service_module_name}" })
      puts "Service module #{service_module_name} in #{namespace} namespace exists. Proceed with deleting this service module..."
      delete_remote_service_module = send_request('/rest/service_module/delete_remote', remote_service_name: "#{namespace}/#{service_module_name}")
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
    puts ''
    return service_module_deleted
  end

  def check_if_service_module_contains_assembly(service_module_name, assembly_name)
    puts 'Check if service module contains assembly:', '------------------------------------------'
    service_module_contains_assembly = false
    service_module_list = send_request('/rest/service_module/list', {})

    if (service_module_list['data'].find { |x| x['display_name'] == service_module_name })
      puts "Service module exists in service module list. Try to find if #{assembly_name} assembly belongs to #{service_module_name} service module..."
      service_module_id = service_module_list['data'].find { |x| x['display_name'] == service_module_name }['id']

      service_module_assembly_list = send_request('/rest/service_module/list_assemblies', service_module_id: service_module_id)
      puts "List of assemblies that belong to service #{service_module_name}:"
      pretty_print_JSON(service_module_assembly_list)

      if (service_module_assembly_list['data'].find { |x| x['display_name'] == assembly_name })
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
    puts ''
    return service_module_contains_assembly
  end

  def check_component_modules_in_service_module(service_module_name, components_list_to_check)
    puts 'Check component modules in service module:', '------------------------------------------'
    all_components_exist_in_service_module = false
    components_exist = []
    service_module_list = send_request('/rest/service_module/list', {})

    if (service_module_list['data'].find { |x| x['display_name'] == service_module_name })
      puts "Service module exists in service module list. Try to find all component modules that belong to #{service_module_name} service module..."
      service_module_id = service_module_list['data'].find { |x| x['display_name'] == service_module_name }['id']
      component_modules_list = send_request('/rest/service_module/list_component_modules', service_module_id: service_module_id)
      pretty_print_JSON(component_modules_list)

      components_list_to_check.each do |component|
        if (component_modules_list['data'].find { |x| x['display_name'] == component })
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

  def delete_assembly(assembly_name, namespace = nil)
    puts 'Delete assembly:', '----------------'
    assembly_deleted = false
    assembly_list = send_request('/rest/assembly/list', subtype: 'template')
    assembly = assembly_list['data'].select { |x| x['display_name'] == assembly_name && x['namespace'] == namespace }

    if !assembly.nil?
      puts 'Assembly exists in assembly list. Proceed with deleting assembly...'
      delete_assembly_response = send_request('/rest/service_module/delete_assembly_template', service_module_id: namespace + ':' + assembly_name.split('/').first, assembly_id: assembly.first['id'], subtype: :template)

      if (delete_assembly_response['status'] == 'ok')
        puts "Assembly #{assembly_name} deleted successfully!"
        assembly_deleted = true
      else
        puts "Assembly #{assembly_name} was not deleted successfully!"
      end
    else
      puts 'Assembly does not exist in assembly template list.'
    end
    puts ''
    return assembly_deleted
  end

  def list_service_modules_with_filter(namespace)
    puts 'List service modules with filter:', '---------------------------------'
    service_modules_retrieved = true
    service_modules_list = send_request('/rest/service_module/list', detail_to_include: [], module_namespace: namespace)
    pretty_print_JSON(service_modules_list)

    if service_modules_list['data'].empty?
      service_modules_retrieved = false
    else
      service_modules_list['data'].each do |cmp|
        if cmp['namespace']['display_name'] != namespace
          service_modules_retrieved = false
          break
        end
      end
    end
    puts ''
    return service_modules_retrieved
  end

  def list_remote_service_modules_with_filter(namespace)
    puts 'List remote service modules with filter:', '------------------------------------'
    service_modules_retrieved = true
    service_modules_list = send_request('/rest/service_module/list_remote', rsa_pub_key: self.ssh_key, module_namespace: namespace)
    pretty_print_JSON(service_modules_list)

    if service_modules_list['data'].empty?
      service_modules_retrieved = false
    else
      service_modules_list['data'].each do |cmp|
        unless cmp['display_name'].include? namespace
          service_modules_retrieved = false
          break
        end
      end
    end
    puts ''
    return service_modules_retrieved
  end
end
