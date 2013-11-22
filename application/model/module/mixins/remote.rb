module DTK
  module ModuleRemoteMixin
    #raises an access rights usage eerror if user does not have access to the remote module
    def get_remote_module_info(action,remote_repo,rsa_pub_key,access_rights,version=nil, remote_namespace=nil)
      unless aug_ws_branch = get_augmented_workspace_branch(Opts.new(:filter => {:version => version, :remote_namespace => remote_namespace}))
        raise ErrorUsage.new("Cannot find version (#{version}) associated with module (#{module_name()})")
      end
      unless remote_repo_name = aug_ws_branch[:repo].linked_remote?(remote_repo)
        if action == :push
          raise ErrorUsage.new("Cannot push module (#{module_name()}) to remote (#{remote_repo}) because it is currently not linked to a remote module")
        else #action == :pull
          raise ErrorUsage.new("Cannot pull module (#{module_name()}) from remote (#{remote_repo}) because it is currently not linked to a remote module")
        end
      end

      remote_params = {
        :module_name => module_name(),
        :module_type => module_type(),
        :remote_repo_name => remote_repo_name
      }
      remote_params.merge!(:version => version) if version
      remote_repo = Repo::Remote.new(remote_repo)
      remote_repo.raise_error_if_no_access(model_handle(),remote_params,access_rights,:rsa_pub_key => rsa_pub_key)
      remote_repo.get_remote_module_info(aug_ws_branch,remote_params)
    end

    #this should be called when the module is linked, but the specfic version is not
    def import_version(remote_repo,version)
      parsed = nil
      module_name = module_name()
      project = get_project()
      aug_head_branch = get_augmented_workspace_branch()
      repo = aug_head_branch && aug_head_branch[:repo] 
      unless repo and repo.linked_remote?(remote_repo)
        raise ErrorUsage.new("Cannot pull module (#{module_name}) from remote (#{remote_repo}) because it is currently not linked to the remote module")
      end
      if get_augmented_workspace_branch(Opts.new(:filter => {:version => version},:donot_raise_error=>true))
        raise ErrorUsage.new("Version (#{version}) for module (#{module_name}) has already been imported")
      end

      local_branch_name = ModuleBranch.workspace_branch_name(project,version)
      Transaction do
        #TODO: may have commit_sha returned in this fn so client can do a reliable pull
        commit_sha = repo.initial_sync_with_remote_repo(remote_repo,local_branch_name,version)
        local_repo_for_imported_version = aug_head_branch.repo_for_version(repo,version)

        opts = {:do_not_raise => true}
        parsed = create_new_version__type_specific(local_repo_for_imported_version,version,opts)
      end
      response = get_workspace_branch_info(version)

      if (parsed.is_a?(ErrorUsage::DSLParsing) || parsed.is_a?(ComponentDSL::ObjectModelForm::ParsingError))
        response[:dsl_parsed_info] = parsed
      else  
        response[:dsl_parsed_info] = parsed[:dsl_parsed_info] if (parsed && !parsed.empty?)
      end

      return response
    end

    # export to a remote repo
    # request_params: hash map containing remote_component_name, remote_component_namespace
    def export(remote_repo,version=nil, remote_component_name = "")
      # TODO: put in version-specfic logic or only deal with versions using push-to-remote
      project = get_project()
      repo = get_workspace_repo()

      component_namespace, component_name, component_version = Repo::Remote::split_qualified_name(remote_component_name)
      version ||= component_version

      # [Amar & Haris] this is temp restriction until rest of logic is properly fixed
      if module_name() != component_name
        raise ErrorUsage.new("We do not support custom module names (via export) at this time.")
      end

      # if repo.linked_remote?(remote_repo)
      #   raise ErrorUsage.new("Cannot export module (#{module_name}) because it is currently linked to a remote module")
      # end

      local_branch = ModuleBranch.workspace_branch_name(project,version)

      unless module_branch_obj = get_module_branch(local_branch)
        raise ErrorUsage.new("Cannot find version (#{version}) associated with module (#{module_name})")
      end

      sp_hash = {
        :cols => [:id,:display_name],
        :filter => [:and, [:eq, :display_name, module_name()], [:eq, :project_project_id,project[:id]]]
      } 
      module_obj = get_obj(project.model_handle(module_type()),sp_hash)
      export_preprocess(module_branch_obj, module_obj)

      #create module on remote repo manager
      module_info = Repo::Remote.new(remote_repo).create_module(module_name,module_type(), component_namespace)

      remote_repo_name = module_info[:git_repo_name]

      # check if remote exists
      if repo.remote_exists?(local_branch, remote_repo_name)
        raise ErrorUsage.new("Remote repo already exists with given name and namespace")
      end

      #link and push to remote repo
      repo.link_to_remote(local_branch,remote_repo_name)
      repo.push_to_remote(local_branch,remote_repo_name)

      RepoRemote.create_repo_remote(model_handle(:repo_remote), module_name, remote_repo_name, component_namespace, repo.id,Opts.new(:set_as_default_if_first => true))

      #update last for idempotency (i.e., this is idempotent check)
      repo.update(:remote_repo_name => remote_repo_name, :remote_repo_namespace => module_info[:remote_repo_namespace])
      
      # NOT SURE WHEN WE NEED THIS (Haris)
      #repo.initial_sync_with_remote_repo(remote_repo,local_branch,version)
      
      remote_repo_name
    end

  end

  module ModuleRemoteClassMixin

    def pull_from_remote(project, local_module_name, remote_repo, version = nil)
      local_branch = ModuleBranch.workspace_branch_name(project, version)
      module_obj = module_exists?(project.id_handle(), local_module_name)

      # validate presence of module (this should never happen)
      raise ErrorUsage.new("Not able to find local module '#{local_module_name}'") unless module_obj
      # validate presence of brach
      raise ErrorUsage.new("Not able to find version '#{version}' for module '#{local_module_name}'") unless module_obj.get_module_branch(local_branch)
      
      repo = module_obj.get_repo!
      repo.initial_sync_with_remote_repo(remote_repo,local_branch,version)

      module_and_branch_info = create_ws_module_and_branch_obj?(project,repo.id_handle(),local_module_name,version)
      module_obj.pull_from_remote__update_from_dsl(repo, module_and_branch_info, version)
    end

    #import from remote repo; directly in this method handles the module/branc and repo level items
    #and then calls import__dsl to handle model and implementaion/files parts depending on what type of module it is

    #  remote_params = {
    #    :repo
    #    :module_namespace
    #    :module_name
    #    :version
    #  }
    #  local_params = {
    #    :module_name
    #  }

    def import(project,remote_params,local_params,opts={})
      #repo_client = Repo::Remote.new(remote_params[:repo])
      #repo_client.get_remote_module_components(remote_params[:module_name], component_type(), remote_params[:module_version], remote_params[:module_namespace])
      #return 1

      repo, version, module_and_branch_info, commit_sha, module_obj, parsed = nil, nil, nil, nil, nil, nil

      Transaction do
        local_branch = ModuleBranch.workspace_branch_name(project,remote_params[:version])
        local_module_name = local_params[:module_name]
        version = remote_params[:version]
        
        if module_obj = module_exists?(project.id_handle(),local_module_name)
          if module_obj.get_module_branch(local_branch)
            # do not raise exception if user wants to ignore component import
            if opts[:ignore_component_error]
              return module_obj
            else
              message = "Conflicts with existing server local module (#{pp_module_name(local_module_name,version)})"
              message += ". To ignore this conflict and use existing module please use -i switch (import-dtkn REMOTE-SERVICE-NAME -i)." if opts[:additional_message]
              raise ErrorUsage.new(message)
            end
          end
        end
      
        remote_repo = Repo::Remote.new(remote_params[:repo])
        begin
          remote_module_info = remote_repo.get_module_info(remote_params.merge(:module_type => module_type()))
        rescue Exception => e
          return {:does_not_exist => "component '#{local_module_name}#{version && "-#{version}"}' does not exist."} if opts[:do_not_raise]
        end
        
        #case on whether the module is created already
        if module_obj
          repo = module_obj.get_repo!()
        else
          #MOD_RESTRUCT: TODO: what entity gets authorized; also this should be done a priori
          remote_repo.authorize_dtk_instance(remote_params[:module_name],remote_params[:module_namespace],module_type())
          
          #create empty repo on local repo manager; 
          #need to make sure that tests above indicate whether module exists already since using :delete_if_exists
          create_opts = {
            :remote_repo_name => remote_module_info[:git_repo_name],
            :remote_repo_namespace => remote_params[:module_namespace],
            :donot_create_master_branch => true,
            :delete_if_exists => true
          }
          repo = create_empty_workspace_repo(project.id_handle(),local_module_name,component_type,create_opts)
        end
        
        commit_sha = repo.initial_sync_with_remote_repo(remote_params[:repo],local_branch,version)
        module_and_branch_info = create_ws_module_and_branch_obj?(project,repo.id_handle(),local_module_name,version)
        module_obj ||= module_and_branch_info[:module_idh].create_object()
        
        opts = {:do_not_raise => true}
        parsed = module_obj.import__dsl(commit_sha,repo,module_and_branch_info,version, opts)
      end
      
      response = module_repo_info(repo,module_and_branch_info,version)
      
      if (parsed.is_a?(ErrorUsage::DSLParsing) || parsed.is_a?(ComponentDSL::ObjectModelForm::ParsingError) || parsed.is_a?(XYZ::ErrorUsage::DanglingComponentRefs))
        response[:dsl_parsed_info] = parsed
      else  
        response[:dsl_parsed_info] = parsed[:dsl_parsed_info] if (parsed && !parsed.empty?)
      end

      response
    end

    def delete_remote(project,remote_params)
      #TODO: put in version specific logic
      if remote_params[:version]
        raise Error.new("TODO: delete_remote when version given")
      end
      remote_repo = Repo::Remote.new(remote_params[:repo])
      error = nil
      begin
        remote_module_info = remote_repo.get_module_info(remote_params.merge(:module_type => module_type()))
       rescue  ErrorUsage => e
        error = e
       rescue Exception 
        error = ErrorUsage.new("Remote component/service (#{remote_params[:module_namespace]}/#{remote_params[:module_name]}) does not exist")
      end

      # delete module on remote repo manager
      unless error
        remote_repo.delete_module(remote_params[:module_name],module_type(),remote_params[:module_namespace])
      end
        
      # unlink any local repos that were linked to this remote module
      local_module_name = remote_params[:module_name]
      sp_hash = {
        :cols => [:id,:display_name],
        :filter => [:and, [:eq, :display_name, local_module_name], [:eq, :project_project_id,project[:id]]]
      } 

      if module_obj = get_obj(project.model_handle(model_type),sp_hash)
        repos = module_obj.get_repos().uniq()
        
        # module_obj.get_repos().each do |repo|
        repos.each do |repo|
          # we remove remote repos
          unless repo_remote_db = RepoRemote.get_remote_repo(repo.model_handle(:repo_remote), repo.id, remote_params[:module_name], remote_params[:module_namespace])
            raise ErrorUsage.new("Remote component/service (#{remote_params[:module_namespace]}/#{remote_params[:module_name]}) does not exist") 
          end

          repo.unlink_remote(remote_params[:repo])

          ::DTK::RepoRemote.delete_repos([repo_remote_db.id_handle()])
        end
      end
     
      raise error if error
    end

    def list_remotes(model_handle)
      unsorted = Repo::Remote.new.list_module_info(module_type()).map do |r|
        el = {:display_name => r[:qualified_name],:type => component_type(), :last_updated => r[:last_updated]} #TODO: hard coded
        if versions = r[:versions]
          el.merge!(:versions => versions.join(", ")) 
        end
        el
      end
      unsorted.sort{|a,b|a[:display_name] <=> b[:display_name]}
    end

  end
end
