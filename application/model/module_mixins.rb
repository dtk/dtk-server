module DTK
  module ModuleMixin
    #export to remote
    def export(version=nil)
      repo = get_library_repo()
      module_name = update_object!(:display_name)[:display_name]
      if repo[:remote_repo_name]
        raise ErrorUsage.new("Cannot export module (#{module_name}) because it is currently linked to a remote module (#{repo[:remote_repo_name]})")
      end

      branch = library_branch(version)
      unless module_branch = get_module_branch(branch)
        raise ErrorUsage.new("Cannot find version (#{version}) associated with module (#{module_name})")
      end
      export_preprocess(module_branch)

      #create module on remote repo manager
      module_info = Repo::Remote.new.create_module(module_name,module_type())
      remote_repo_name = module_info[:git_repo_name]

      #link and push to remote repo
      repo.link_to_remote(remote_repo_name,branch)
      repo.push_to_remote(remote_repo_name,branch)

      #update last for idempotency (i.e., this is idempotent check)
      repo.update(:remote_repo_name => remote_repo_name, :remote_repo_namespace => module_info[:remote_repo_namespace])
      remote_repo_name
    end

    def push_to_remote(version=nil)
      repo = get_library_repo()
      module_name = update_object!(:display_name)[:display_name]
      unless remote_repo_name = repo[:remote_repo_name]
        raise ErrorUsage.new("Cannot push module (#{module_name}) to remote because it is currently not linked to a remote module")
      end
      branch = library_branch(version)
      unless get_module_branch(branch)
        raise ErrorUsage.new("Cannot find version (#{version}) associated with module (#{module_name})")
      end
      merge_rel = repo.ret_remote_merge_relationship(remote_repo_name,branch,:fetch_if_needed => true)
      pp [:debug_merge_rel,merge_rel]
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

    def get_repos()
      get_objs_uniq(:repos)
    end
    def get_library_repo()
      sp_hash = {
        :cols => [:id,:display_name,:library_repo,:library_library_id]
      }
      row = get_obj(sp_hash)
      #opportunistically set display name and library_library_id on module
      self[:display_name] ||= row[:display_name]
      self[:library_library_id] ||= row[:library_library_id]
      row[:repo]
    end

    def get_implementations()
      get_objs_uniq(:implementations)
    end
    def get_library_implementations()
      get_objs_uniq(:library_implementations)
    end
    def module_type()
      self.class.module_type()
    end
   private
    def library_branch(version=nil)
      library_id = update_object!(:library_library_id)[:library_library_id]
      library_idh = id_handle(:model_name => :library, :id => library_id)
      ModuleBranch.library_branch_name(library_idh,version)
    end

    def get_module_branch(branch)
      sp_hash = {
        :cols => [:module_branches]
      }
      module_branches = get_objs(sp_hash).map{|r|r[:module_branch]}
      module_branches.find{|mb|mb[:branch] == branch}
    end
  end

  module ModuleClassMixin
    #import from remote repo
    def import(library_idh,remote_module_name,remote_namespace,version=nil)
      module_name = remote_module_name
      raise_error_if_library_module_exists(library_idh,module_name)

      unless remote_module_info = Repo::Remote.new.get_module_info(remote_module_name,module_type(),remote_namespace)
        raise ErrorUsage.new("Remote module (#{remote_namespace}/#{remote_module_name}) does not exist")
      end
      unless git_repo_name = remote_module_info[:git_repo_name]
        raise Error.new("Remote repo info does not have field (git_repo_name)") 
      end

      #TODO: this will be done a priori (or not at all because of movingto model wheer duing create owner sets rights)
      Repo::Remote.new.authorize_dtk_instance(remote_module_name,module_type())

      #create empty repo on local repo manager; 
      module_specific_type = 
        case module_type() 
         when :service_module
          :service_module
         when :component_module
          :puppet #TODO: hard wired
        end

      #need to make sure that tests above indicate whether module exists already since using :delete_if_exists
      create_opts = {:remote_repo_name => git_repo_name,:remote_repo_namespace => remote_namespace,:delete_if_exists => true}
      repo = create_empty_repo_and_local_clone(library_idh,module_name,module_specific_type,create_opts)

      branch = ModuleBranch.library_branch_name(library_idh,version)
      repo.synchronize_with_remote_repo(branch)
      module_branch_idh = import_postprocess(repo,library_idh,remote_module_name,remote_namespace,version)
      module_branch_idh
    end

    def list_remotes(model_handle)
      Repo::Remote.new.list_module_qualified_names(module_type()).map{|r|{:display_name => r[:name]}}
    end

    def module_type()
      model_name()
    end

    def check_valid_id(model_handle,id)
      check_valid_id_default(model_handle,id)
    end
    def name_to_id(model_handle,name)
      name_to_id_default(model_handle,name)
    end

    def add_user_direct_access(model_handle,rsa_pub_key)
      repo_user = RepoUser.add_repo_user?(:client,model_handle.createMH(:repo_user),rsa_pub_key)
      model_name = model_handle[:model_name]
      return if repo_user.has_direct_access?(model_name,:donot_update => true)
      repo_user.update_direct_access(model_name,true)
      repos = get_all_repos(model_handle)
      unless repos.empty?
        repo_names = repos.map{|r|r[:repo_name]}
        RepoManager.set_user_rights_in_repos(repo_user[:username],repo_names,DefaultAccessRights)

        repos.map{|repo|RepoUserAcl.update_model(repo,repo_user,DefaultAccessRights)}
      end
    end
    DefaultAccessRights = "RW+"

    def remove_user_direct_access(model_handle,rsa_pub_key)
      repo_user = RepoUser.get_matching_repo_user(model_handle.createMH(:repo_user),:ssh_rsa_pub_key => rsa_pub_key)
      return unless repo_user

      model_name = model_handle[:model_name]
      return unless repo_user.has_direct_access?(model_name)

      username = repo_user[:username]
      RepoManager.delete_user(username)
      repos = get_all_repos(model_handle)
      unless repos.empty?
        repo_names = repos.map{|r|r[:repo_name]}
        RepoManager.remove_user_rights_in_repos(username,repo_names)
        #repo user acls deleted by foriegn key cascade
      end

      if repo_user.any_direct_access_except?(model_name)
        repo_user.update_direct_access(model_name,false)
      else
        delete_instance(repo_user.id_handle())
      end
    end

    def delete(idh)
      module_obj = idh.create_object()
      unless module_obj.get_associated_target_instances().empty?
        raise ErrorUsage.new("Cannot delete a module if one or more of its instances exist in a target")
      end
      impls = module_obj.get_implementations()
      delete_instances(impls.map{|impl|impl.id_handle()})
      repos = module_obj.get_repos()
      repos.each{|repo|RepoManager.delete_repo(repo)}
      delete_instances(repos.map{|repo|repo.id_handle()})
      delete_instance(idh)
    end

    def create_empty_repo_and_local_clone(library_idh,module_name,module_specific_type,opts={})
      auth_repo_users = RepoUser.authorized_users(library_idh.createMH(:repo_user))
      repo_user_acls = auth_repo_users.map do |repo_username|
        {
          :repo_username => repo_username,
          :access_rights => "RW+"
        }
      end
      Repo.create_empty_repo_and_local_clone(library_idh,module_name,module_specific_type,repo_user_acls,opts)
    end

    #TODO: change so get versions from cm or sm branches
    def list_from_library(impl_mh,opts={})
      library_idh = opts[:library_idh]
      lib_filter = (library_idh ? [:eq, :library_library_id, library_idh.get_id()] : [:neq, :library_library_id, nil])
      sp_hash = {
        :cols => [:id, :display_name,:version],
        :filter => lib_filter
      }
      get_objs(impl_mh,sp_hash)
    end


   private
    def get_all_repos(mh)
      get_objs(mh,{:cols => [:repos]}).inject(Hash.new) do |h,r|
        repo = r[:repo]
        h[repo[:id]] ||= repo
        h
      end.values
    end

    def raise_error_if_library_module_exists(library_idh,module_name)
      sp_hash = {
        :cols => [:id,:display_name],
        :filter => [:and, [:eq, :library_library_id, library_idh.get_id()],
                    [:eq, :display_name, module_name]]
      }
      module_object = get_obj(library_idh.createMH(model_name),sp_hash)
      if module_object
        raise ErrorUsage.new("Conflicts with existing library module (#{module_name})")
      end
    end

    def create_lib_module_and_branch_obj?(library_idh,repo_idh,module_name,input_version)
      ref = module_name
      mb_create_hash = ModuleBranch.ret_lib_create_hash(model_name,library_idh,repo_idh,input_version)
      version = mb_create_hash.values.first[:version]
      create_hash = {
        model_name.to_s => {
          ref => {
            :display_name => module_name,
            :module_branch => mb_create_hash
          }
        }
      }
      #TODO: double check that this returns just one item as opposed to one per child of service_module
      module_id = create_from_hash(library_idh,create_hash).first[:id]
      module_idh = library_idh.createIDH(:id => module_id, :model_name => model_name)
      parent_col = (model_name == :service_module ? ModuleBranch.service_module_id_col() : ModuleBranch.component_module_id_col())
      sp_hash = {
        :cols => [:id,:display_name],
        :filter => [:and, [:eq, parent_col, module_idh.get_id()], [:eq, :ref, mb_create_hash.keys.first]]
      }
      module_branch_idh = get_objs(library_idh.createMH(:module_branch),sp_hash).map{|r|r.id_handle()}.first
      {:version => version, :module_idh => module_idh,:module_branch_idh => module_branch_idh}
    end
  end
end
