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
end
