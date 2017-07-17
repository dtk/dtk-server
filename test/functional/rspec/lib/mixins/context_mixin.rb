module ContextMixin
  def set_default_context(context_name)
    puts 'Set default context:', '--------------------'
    default_context_set = false
    response = send_request('/rest/assembly/set_default_context', :assembly_id => context_name)
    if response['status'] == 'ok'
      puts "context #{context_name} has been set as default!"
      default_context_set = true
    else
      puts "context #{context_name} has not been set as default!"
    end
    puts ''
    default_context_set
  end

  def create_context(provider_name, region)
    puts 'Create context:', '--------------'
    context_created = false
    list_providers = send_request('/rest/context/list', subtype: :template)
    if (list_providers['data'].find { |x| x['display_name'].include? provider_name })
      puts "Provider #{provider_name} exists! Create context for provider..."
      provider_id = list_providers['data'].find { |x| x['display_name'].include? provider_name }['id']
      create_context_response = send_request('/rest/context/create', context_name: provider_name, context_template_id: provider_id, region: region)
      context_created = create_context_response['data']['success']
      puts "context #{provider_name}-#{region} created successfully!"
    else
      puts "Provider #{provider_name} does not exist!"
    end
    puts ''
    context_created
  end

  def check_if_context_exists_in_provider(provider_name, context_name)
    puts 'Check if context exists in provider:', '-----------------------------------'
    context_exists = false
    list_providers = send_request('/rest/context/list', subtype: :template)

    if (list_providers['data'].find { |x| x['display_name'].include? provider_name })
      puts "Provider #{provider_name} exists! Get provider's contexts..."
      provider_id = list_providers['data'].find { |x| x['display_name'].include? provider_name }['id']
      list_contexts = send_request('/rest/context/list', subtype: :instance, parent_id: provider_id)

      if (list_contexts['data'].find { |x| x['display_name'].include? context_name })
        puts "context #{context_name} exists in #{provider_name} provider!"
        context_exists = true
      else
        puts "context #{context_name} does not exist in #{provider_name} provider!"
      end
    else
      puts "Provider #{provider_name} does not exist!"
    end
    puts ''
    context_exists
  end

  def delete_context_from_provider(context_name)
    puts 'Delete context from provider:', '----------------------------'
    context_deleted = false

    delete_context = send_request('/rest/context/delete_and_destroy', context_id: context_name, type: 'instance')
    if delete_context['status'] == 'ok'
      puts "context #{context_name} has been deleted successfully!"
      context_deleted = true
    else
      puts "context #{context_name} has not been deleted successfully!"
    end
    puts ''
    context_deleted
  end

  def check_if_assembly_exists_in_context(assembly_name, context_name)
    puts 'Check if assembly exists in context:', '-----------------------------------'
    assembly_exists = false
    assembly_list = send_request('/rest/context/info_about', context_id: context_name, about: 'assemblies')

    if (assembly_list['data'].find { |x| x['display_name'].include? assembly_name })
      puts "Assembly #{assembly_name} exists in context #{context_name}!"
      assembly_exists = true
    else
      puts "Assembly #{assembly_name} does not exist in context #{context_name}!"
    end
    puts ''
    assembly_exists
  end

  def check_if_node_exists_in_context(node_name, context_name)
    puts 'Check if node exists in context:', '-------------------------------'
    node_exists = false
    node_list = send_request('/rest/context/info_about', context_id: context_name, about: 'nodes')

    if (node_list['data'].find { |x| x['display_name'].include? node_name })
      puts "Node #{node_name} exists in context #{context_name}!"
      node_exists = true
    else
      puts "Node #{node_name} does not exist in context #{context_name}!"
    end
    puts ''
    node_exists
  end

  def get_default_context
    puts "Get default context service instance id:", "---------------------------------------"
    service_id = nil
    default_context_service_response = send_request('/rest/assembly/get_default_context', {})

    if default_context_service_response['status'] == 'ok'
      puts "Default context service instance succesfully found."
      service_id = default_context_service_response['data']['id']
    else
      puts "Default context service was not succesfully found."
    end

    puts ''
    service_id
  end

  def get_default_context_name
    puts "Get default context service instance id:", "---------------------------------------"
    service_name = nil
    default_context_service_response = send_request('/rest/assembly/get_default_context', {})

    if default_context_service_response['status'] == 'ok'
      puts "Default context service instance succesfully found."
      service_name = default_context_service_response['data']['display_name']
      puts service_name
    else
      puts "Default context service was not succesfully found."
    end

    puts ''
    service_name
  end
  
  def stage_service_in_specific_context(context_name)
    #Get list of assemblies, extract selected assembly, stage service to defined context and return its service id
    puts 'Stage service in specific context:', '---------------------------------'
    service_id = nil
    extract_id_regex = /id: (\d+)/
    assembly_list = send_request('/rest/assembly/list', subtype: 'template')

    puts 'List of avaliable assemblies: '
    pretty_print_JSON(assembly_list)

    test_template = assembly_list['data'].find { |x| x['display_name'] == @assembly }

    if (!test_template.nil?)
      puts "Assembly #{@assembly} found!"
      assembly_id = test_template['id']
      puts "Assembly id: #{assembly_id}"

      stage_service_response = send_request('/rest/assembly/stage', assembly_id: assembly_id, name: @service_name, context_id: context_name)
      if (stage_service_response['data'].include? "name: #{@service_name}")
        puts "Stage of #{@assembly} assembly completed successfully!"
        service_id_match = stage_service_response['data'].match(extract_id_regex)
        self.service_id = service_id_match[1].to_i
        puts "Service id for a staged service: #{self.service_id}"
      else
        puts 'Stage service didnt pass!'
      end
    else
      puts "Assembly #{@assembly} not found!"
    end
    puts ''
  end
end
