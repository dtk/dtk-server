module DTK
  module ModuleRemoteMixin
    #either indicates no auth or sends back info needed to push changes to remote
    def check_remote_auth(remote_repo,rsa_pub_key,access_rights,version=nil)
      unless aug_branch = get_augmented_workspace_branch(version)
        raise ErrorUsage.new("Cannot find version (#{version}) associated with module (#{module_name()})")
      end
      unless aug_branch[:repo].linked_remote?(remote_repo)
        raise ErrorUsage.new("Cannot push module (#{module_name()}) to remote (#{remote_repo}) because it is currently not linked to the remote module")
      end

      remote_repo = Repo::Remote.new(remote_repo)
      remote_params = {
        :module_name => module_name(),
        :module_type => module_type()
      }
      remote_repo.check_remote_auth(remote_params,rsa_pub_key,access_rights,version)
    end

    #export to a remote repo
    def export(remote_repo,version=nil)
      #TODO: put in version-specfic logic
      project = get_project()
      repo = get_workspace_repo()
      module_name = update_object!(:display_name)[:display_name]
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

    def pull_from_remote(version=nil)
      raise Error.new("MOD_RESTRUCT: needs to be rewritten") # made one change so far:  self.class.import_postprocess(project,repo,module_name,version)
      repo = get_library_repo()
      update_object!(:display_name,:library_library_id)
      module_name = self[:display_name]
      library_idh = id_handle(:model_name => :library, :id => self[:library_library_id])

      unless remote_repo_name = repo[:remote_repo_name]
        raise ErrorUsage.new("Cannot pull from remote because local module (#{module_name}) is not linked to a remote module; use import.")
      end
      branch = library_branch_name(version)
      unless get_module_branch(branch)
        raise ErrorUsage.new("Cannot find version (#{version}) associated with module (#{module_name})")
      end
      merge_rel = repo.ret_remote_merge_relationship(remote_repo_name,branch,:fetch_if_needed => true)
      case merge_rel
       when :equal,:local_ahead 
        #TODO: for reboust idempotency under errors may have under this same as under :local_behind
        raise ErrorUsage.new("No changes in remote linked to module (#{module_name}) to pull from")
       when :local_behind
        repo.synchronize_with_remote_repo(branch)
        self.class.import_postprocess(project,repo,module_name,version)
        #update ws from library
        update_ws_branch_from_lib_branch?(version)
       when :branchpoint
        #TODO: put in flag to push_to_remote that indicates that in this condition go ahead and do a merge or flag to 
        #mean discard local changes
        #the relevant steps for discard local changes are
        #1 find merge base for  refs/heads/master and refs/remotes/remote/master; call it sha-mp
        #2 execute  git reset --hard sha-mp
        #3 execute  git push --force origin sha-mp:master
        #4 execute code under case local_behind
        raise ErrorUsage.new("Merge from remote repo is needed before can pull changes into module (#{module_name})")
       else 
        raise Error.new("Unexpected type (#{merge_rel}) returned from ret_remote_merge_relationship")
      end
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
      merge_rel = repo.ret_remote_merge_relationship(remote_repo_name,branch,:fetch_if_needed => true)
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
    #import from remote repo
    def import(project,remote_params,local_params)
      local_branch = ModuleBranch.workspace_branch_name(project,remote_params[:version])
      if module_obj = module_exists?(project.id_handle(),local_params[:module_name])
        if module_obj.get_module_branch(local_branch)
          raise ErrorUsage.new("Conflicts with existing local module (#{pp_module_name(local_params[:module_name],remote_params[:version])})")
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
          :create_branches => [local_branch],
          :delete_if_exists => true
        }
        repo = create_empty_workspace_repo(project.id_handle(),local_params[:module_name],component_type,create_opts)
      end

      repo.initial_synchronize_with_remote_repo(remote_params,local_branch)
      module_branch_idh = import_postprocess(project,repo,local_params[:module_name],remote_params[:version])
      module_branch_idh
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
