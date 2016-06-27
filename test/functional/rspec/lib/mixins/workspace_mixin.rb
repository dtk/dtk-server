module WorkspaceMixin
  def get_workspace_id
    # response = send_request('/rest/assembly/list_with_workspace', {})
    # workspace = response['data'].find { |x| x['display_name'] == 'workspace' }['id']
    # workspace = "workspace" if workspace.nil?
    # workspace 
    self.workspace_id
  end

  def purge_content(service_id)
    puts 'Purge content:', '--------------'
    content_purged = false

    response = send_request('/rest/assembly/purge', assembly_id: service_id)
    if response['status'].include? 'ok'
      puts 'Content has been purged successfully!'
      content_purged = true
    else
      puts 'Content has not been purged successfully!'
    end
    puts ''
    content_purged
  end

  def create_workspace(workspace_name = nil, workspace_target = nil)
    puts 'Create workspace:', '-----------------'
    workspace_created = false
    puts workspace_name    
    extract_id_regex = /id: (\d+)/

    create_workspace_params = {}
    create_workspace_params[:workspace_name] = workspace_name if workspace_name
    create_workspace_params[:parent_service] = workspace_target if workspace_target

    create_workspace_response = send_request('/rest/assembly/create_workspace', create_workspace_params)
    pretty_print_JSON(create_workspace_response)
    
    if create_workspace_response['status'].include? 'ok'
      puts 'Workspace has been successfully created'
      send_request('/rest/assembly/list', {})
      workspace_id_match = create_workspace_response['data'].match(extract_id_regex)
      self.workspace_id = workspace_id_match[1].to_i
      self.service_id = self.workspace_id
      puts "Workspace id: #{self.workspace_id}"
      workspace_created = true
    else
      puts 'Workspace has not been succesfully created'
    end

    puts ''
    workspace_created
  end

  def delete_workspaces_in_target(target_instance = 'target', assembly_template = 'workspace')
    puts "Delete workspace instances in #{target_instance} target service instance", "------------------------------------------------------------------------"

    workspace_instance_list = list_existing_workspaces(target_instance, assembly_template)
    workspace_instances_deleted = false
  
    if workspace_instance_list
      puts "Workspace instances list "
      extracted_workspace_id_list = workspace_instance_list.map { |x| x['id'] }
      extracted_workspace_id_list.each do |id| 

      delete_workspace_instance_response = send_request('/rest/assembly/delete', {:assembly_id=>id})
        if delete_workspace_instance_response['status'] != 'ok'
          puts "Workspace #{id} was not deleted successfully."          
          workspace_instances_deleted = false
          break
        else 
          puts "Workspace #{id} was deleted successfully."
          workspace_instances_deleted = true
        end
      end
      if workspace_instances_deleted
        puts "Delete of workspace service instances was successful"
      else
        puts "Delete of workspace service instances was not successful"
      end
    else
      puts "Could not get workspace service instance list"
    end

    puts ''
    workspace_instances_deleted
  end

  def list_existing_workspaces(target_instance = 'target', assembly_template = 'workspace')
    # Get list of existing workspace service instances in a specific target
    puts "List workspace service instances in #{target_instance}:", "-------------------------------------------------------"
    service_instance_list = send_request('/rest/assembly/list', {:detail_level=>'nodes', :subtype=>'instance', :include_namespaces => true})
    workspace_instance_list = nil

    if service_instance_list['status'] == 'ok' 
      workspace_instance_list = service_instance_list['data'].select{ |x| x['assembly_template'] == assembly_template && x['target'] == target_instance }
      
      if workspace_instance_list.length.zero?
        puts "No workspace service instances found for #{target_instance} target instance."
        workspace_instance_list = nil
      else
        puts "#{workspace_instance_list.length} workspace service instances found for #{target_instance} target instance: "
        pretty_print_JSON(workspace_instance_list) 
      end
    else
      puts "Could not get service instance list."
    end

    puts ''
    workspace_instance_list
  end
end
