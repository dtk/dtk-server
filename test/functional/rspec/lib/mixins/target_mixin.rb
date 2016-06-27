module TargetMixin
  def set_default_target(target_name)
    puts 'Set default target:', '--------------------'
    default_target_set = false
    response = send_request('/rest/assembly/set_default_target', :assembly_id => target_name)
    if response['status'] == 'ok'
      puts "Target #{target_name} has been set as default!"
      default_target_set = true
    else
      puts "Target #{target_name} has not been set as default!"
    end
    puts ''
    default_target_set
  end

  def create_target(provider_name, region)
    puts 'Create target:', '--------------'
    target_created = false
    list_providers = send_request('/rest/target/list', subtype: :template)
    if (list_providers['data'].find { |x| x['display_name'].include? provider_name })
      puts "Provider #{provider_name} exists! Create target for provider..."
      provider_id = list_providers['data'].find { |x| x['display_name'].include? provider_name }['id']
      create_target_response = send_request('/rest/target/create', target_name: provider_name, target_template_id: provider_id, region: region)
      target_created = create_target_response['data']['success']
      puts "Target #{provider_name}-#{region} created successfully!"
    else
      puts "Provider #{provider_name} does not exist!"
    end
    puts ''
    target_created
  end

  def check_if_target_exists_in_provider(provider_name, target_name)
    puts 'Check if target exists in provider:', '-----------------------------------'
    target_exists = false
    list_providers = send_request('/rest/target/list', subtype: :template)

    if (list_providers['data'].find { |x| x['display_name'].include? provider_name })
      puts "Provider #{provider_name} exists! Get provider's targets..."
      provider_id = list_providers['data'].find { |x| x['display_name'].include? provider_name }['id']
      list_targets = send_request('/rest/target/list', subtype: :instance, parent_id: provider_id)

      if (list_targets['data'].find { |x| x['display_name'].include? target_name })
        puts "Target #{target_name} exists in #{provider_name} provider!"
        target_exists = true
      else
        puts "Target #{target_name} does not exist in #{provider_name} provider!"
      end
    else
      puts "Provider #{provider_name} does not exist!"
    end
    puts ''
    target_exists
  end

  def delete_target_from_provider(target_name)
    puts 'Delete target from provider:', '----------------------------'
    target_deleted = false

    delete_target = send_request('/rest/target/delete_and_destroy', target_id: target_name, type: 'instance')
    if delete_target['status'] == 'ok'
      puts "Target #{target_name} has been deleted successfully!"
      target_deleted = true
    else
      puts "Target #{target_name} has not been deleted successfully!"
    end
    puts ''
    target_deleted
  end

  def check_if_assembly_exists_in_target(assembly_name, target_name)
    puts 'Check if assembly exists in target:', '-----------------------------------'
    assembly_exists = false
    assembly_list = send_request('/rest/target/info_about', target_id: target_name, about: 'assemblies')

    if (assembly_list['data'].find { |x| x['display_name'].include? assembly_name })
      puts "Assembly #{assembly_name} exists in target #{target_name}!"
      assembly_exists = true
    else
      puts "Assembly #{assembly_name} does not exist in target #{target_name}!"
    end
    puts ''
    assembly_exists
  end

  def check_if_node_exists_in_target(node_name, target_name)
    puts 'Check if node exists in target:', '-------------------------------'
    node_exists = false
    node_list = send_request('/rest/target/info_about', target_id: target_name, about: 'nodes')

    if (node_list['data'].find { |x| x['display_name'].include? node_name })
      puts "Node #{node_name} exists in target #{target_name}!"
      node_exists = true
    else
      puts "Node #{node_name} does not exist in target #{target_name}!"
    end
    puts ''
    node_exists
  end

  def get_default_target
    puts "Get default target service instance id:", "---------------------------------------"
    service_id = nil
    default_target_service_response = send_request('/rest/assembly/get_default_target', {})

    if default_target_service_response['status'] == 'ok'
      puts "Default target service instance succesfully found."
      service_id = default_target_service_response['data']['id']
    else
      puts "Default target service was not succesfully found."
    end

    puts ''
    service_id
  end

  def get_default_target_name
    puts "Get default target service instance id:", "---------------------------------------"
    service_name = nil
    default_target_service_response = send_request('/rest/assembly/get_default_target', {})

    if default_target_service_response['status'] == 'ok'
      puts "Default target service instance succesfully found."
      service_name = default_target_service_response['data']['display_name']
      puts service_name
    else
      puts "Default target service was not succesfully found."
    end

    puts ''
    service_name
  end
  
  def stage_service_in_specific_target(target_name)
    #Get list of assemblies, extract selected assembly, stage service to defined target and return its service id
    puts 'Stage service in specific target:', '---------------------------------'
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

      stage_service_response = send_request('/rest/assembly/stage', assembly_id: assembly_id, name: @service_name, target_id: target_name)
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
