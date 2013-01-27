module DTK
  module ModuleRemoteMixin
    #raises an access rights usage eerror if user does not have access to the remote module
    def get_remote_module_info(action,remote_repo,rsa_pub_key,access_rights,version=nil)
      unless aug_ws_branch = get_augmented_workspace_branch(version)
        raise ErrorUsage.new("Cannot find version (#{version}) associated with module (#{module_name()})")
      end
      unless remote_repo_name = aug_ws_branch[:repo].linked_remote?(remote_repo)
        if action == :push
          raise ErrorUsage.new("Cannot push module (#{module_name()}) to remote (#{remote_repo}) because it is currently not linked to the remote module")
        else #action == :pull
          raise ErrorUsage.new("Cannot pull module (#{module_name()}) from remote (#{remote_repo}) because it is currently not linked to the remote module")
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
      raise Error.new("MOD_RESTRUCT: must be rewritten")
      module_name = module_name()
      project = get_project()
      aug_head_branch = get_augmented_workspace_branch(nil)
      repo = aug_head_branch && aug_head_branch[:repo]
      unless repo and repo.linked_remote?(remote_repo)
        raise ErrorUsage.new("Cannot pull module (#{module_name}) from remote (#{remote_repo}) because it is currently not linked to the remote module")
      end
      if get_augmented_workspace_branch(version,:donot_raise_error=>true)
        raise ErrorUsage.new("Version (#{version}) for module (#{module_name}) has already been imported")
      end

      local_branch = ModuleBranch.workspace_branch_name(project,version)
      commit_sha = repo.initial_sync_with_remote_repo(remote_repo,local_branch,version)
      module_repo_info = self.class.import_postprocess(project,aug_head_branch,module_name,commit_sha,version)
      module_repo_info
    end

    #MOD_RESTRUCT: needes to be updated
    def pull_from_remote_if_fast_foward(remote_repo,version=nil)
      raise Error.new("MOD_RESTRUCT: Needs to be updated")
      unless aug_branch = get_augmented_workspace_branch(version)
        raise ErrorUsage.new("Cannot find version (#{version}) associated with module (#{module_name()})")
      end
      unless aug_branch[:repo].linked_remote?(remote_repo)
        raise ErrorUsage.new("Cannot pull module (#{module_name()}) from remote (#{remote_repo}) because it is currently not linked to the remote module")
      end

      repo = aug_branch[:repo]
      local_branch = aug_branch[:branch]
      merge_rel = repo.ret_remote_merge_relationship(remote_repo,local_branch,version,:fetch_if_needed => true)
      case merge_rel
       when :equal,:local_ahead 
        #TODO: for rebost idempotency under errors may have under this same as under :local_behind
        raise ErrorUsage.new("No changes in remote (#{remote_repo}) linked to module (#{module_name}) to pull from")
       when :local_behind
        repo.synchronize_with_remote_repo(remote_repo,local_branch,version)
        project = get_project()
        self.class.import_postprocess(project,repo,commit_sha,module_name,version)
       when :branchpoint
        #TODO: put in flag to push_to_remote that indicates that in this condition go ahead and do a merge or flag to 
        #mean discard local changes
        #the relevant steps for discard local changes are
        #1 find merge base for  refs/heads/master and refs/remotes/remote/master; call it sha-mp
        #2 execute  git reset --hard sha-mp
        #3 execute  git push --force origin sha-mp:master
        #4 execute code under case local_behind
        raise ErrorUsage.new("Merge is needed; this must be done on workspace clone; issue command to clone module to workspace and then try this command again")
       else 
        raise Error.new("Unexpected type (#{merge_rel}) returned from ret_remote_merge_relationship")
      end
    end

    #export to a remote repo
    def export(remote_repo,version=nil)
      #TODO: put in version-specfic logic
      project = get_project()
      repo = get_workspace_repo()
      module_name = module_name()
      if repo.linked_remote?(remote_repo)
        raise ErrorUsage.new("Cannot export module (#{module_name}) because it is currently linked to a remote module")
      end

      local_branch = ModuleBranch.workspace_branch_name(project,version)
      unless module_branch_obj = get_module_branch(local_branch)
        raise ErrorUsage.new("Cannot find version (#{version}) associated with module (#{module_name})")
      end
      export_preprocess(module_branch_obj)

      #create module on remote repo manager
      module_info = Repo::Remote.new(remote_repo).create_module(module_name,module_type())
      remote_repo_name = module_info[:git_repo_name]

      #link and push to remote repo
      repo.link_to_remote(local_branch,remote_repo_name)
      repo.push_to_remote(local_branch,remote_repo_name)

      #update last for idempotency (i.e., this is idempotent check)
      repo.update(:remote_repo_name => remote_repo_name, :remote_repo_namespace => module_info[:remote_repo_namespace])
      remote_repo_name
    end

    def push_to_remote__deprecate(version=nil) #MOD_RESTRUCT
      repo = get_library_repo()
      module_name = update_object!(:display_name)[:display_name]
      unless remote_repo_name = repo[:remote_repo_name]
        raise ErrorUsage.new("Cannot push module (#{module_name}) to remote because it is currently not linked to a remote module")
      end
      branch = library_branch_name(version)
      unless get_module_branch(branch)
        raise ErrorUsage.new("Cannot find version (#{version}) associated with module (#{module_name})")
      end
      merge_rel = repo.ret_remote_merge_relationship(Repo::Remote.default_remote_repo(),branch,version,:fetch_if_needed => true)
      case merge_rel
       when :equal,:local_behind 
        raise ErrorUsage.new("No changes in module (#{module_name}) to push to remote")
       when :local_ahead
        repo.push_to_remote(remote_repo_name,branch)
       when :branchpoint
        #TODO: put in flag to push_to_remote that indicates that in this condition go ahead and do a merge
        raise ErrorUsage.new("Merge from remote repo is needed before can push changes to module (#{module_name})")
       else 
        raise Error.new("Unexpected type (#{merge_rel}) returned from ret_remote_merge_relationship")
      end
    end

  end

  module ModuleRemoteClassMixin
    #import from remote repo; directly in this method handles the module/branc and repo level items
    #and then calls import__dsl to handle model and implementaion/files parts depending on what type of module it is
    def import(project,remote_params,local_params)
      local_branch = ModuleBranch.workspace_branch_name(project,remote_params[:version])
      local_module_name = local_params[:module_name]
      version = remote_params[:version]
      if module_obj = module_exists?(project.id_handle(),local_module_name)
        if module_obj.get_module_branch(local_branch)
          raise ErrorUsage.new("Conflicts with existing local module (#{pp_module_name(local_module_name,version)})")
        end
      end
      
      remote_repo = Repo::Remote.new(remote_params[:repo])
      remote_module_info = remote_repo.get_module_info(remote_params.merge(:module_type => module_type()))

      #case on whether the module is created already
      if module_obj
        repos = module_obj.get_repos()
        unless repos.size == 1
          raise Error.new("unexpected that number of matching repos is not equal to 1")
        end
        repo = repos.first()
      else
        #MOD_RESTRUCT: TODO: what entity gets authorized; also this should be done a priori
        remote_repo.authorize_dtk_instance(remote_params[:module_name],module_type())

        #create empty repo on local repo manager; 
        #need to make sure that tests above indicate whether module exists already since using :delete_if_exists
        create_opts = {
          :remote_repo_name => remote_module_info[:git_repo_name],
          :remote_repo_namespace => remote_params[:namespace],
          :donot_create_master_branch => true,
          :delete_if_exists => true
        }
        repo = create_empty_workspace_repo(project.id_handle(),local_module_name,component_type,create_opts)
      end

      commit_sha = repo.initial_sync_with_remote_repo(remote_params[:repo],local_branch,version)
      module_and_branch_info = create_ws_module_and_branch_obj?(project,repo.id_handle(),local_module_name,version)
      module_obj ||= module_and_branch_info[:module_idh].create_object()
      
      module_obj.import__dsl(commit_sha,repo,module_and_branch_info)
      module_repo_info(repo,module_and_branch_info)
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
        error = ErrorUsage.new("Remote module (#{remote_params[:module_namespace]}/#{remote_params[:module_name]}) does not exist")
      end

      #delete module on remote repo manager
      unless error
        remote_repo.delete_module(remote_params[:module_name],module_type())
      end
        
      #unlink any local repos that were linked to this remote module
      local_module_name = remote_params[:module_name]
      sp_hash = {
        :cols => [:id,:display_name],
        :filter => [:and, [:eq, :display_name, local_module_name], [:eq, :project_project_id,project[:id]]]
      } 
      if module_obj = get_obj(project.model_handle(model_type),sp_hash)
        module_obj.get_repos().each{|repo|repo.unlink_remote(remote_params[:repo])}
      end
      raise error if error
    end

    def list_remotes(model_handle)
      unsorted = Repo::Remote.new.list_module_info(module_type()).map do |r|
        el = {:display_name => r[:qualified_name],:type => component_type()} #TODO: hard coded
        if versions = r[:versions]
          el.merge!(:version => versions.join(", ")) #TODO: change to ':versions' after sync with client
        end
        el
      end
      unsorted.sort{|a,b|a[:display_name] <=> b[:display_name]}
    end

  end
end
