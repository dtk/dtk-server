module DTK
  module ServiceOrComponentModuleMixin
    def get_repos()
      get_objs_uniq(:repos)
    end
    def get_implementations()
      get_objs_uniq(:implementations)
    end
    def get_library_implementations()
      get_objs_uniq(:library_implementations)
    end
    def get_target_instances()
      if id_handle[:model_name] == :service_module
        raise Error.new("TODO: not implemented yet")
      end
      get_objs_uniq(:target_instances)
    end
  end

  module ServiceOrComponentModuleClassMixin
    def add_user_direct_access(rsa_pub_key)
      model_handle = user_obj.id_handle().createMH(model_name)
      repo_user = RepoUser.dd_repo_user?(:client,model_handle.createMH(:repo_user),rsa_pub_key)
      repo_names = get_all_repos(model_handle).map{|r|r[:repo][:repo_name]}
      unless repo_names.empty?
        RepoManager.set_user_rights_in_repos(username,repo_names,"RW+")
      end
    end

    def add_user_direct_access_old(rsa_pub_key)
      user_obj = CurrentSession.new.get_user_object()
      #block called only if key is not already there; calls update model at end to be more idempotent
      user_obj.add_ssh_rsa_pub_key?(rsa_pub_key) do |first_key_for_user|
        username = user_obj[:username]
        if first_key_for_user
          RepoManager.add_user(username,rsa_pub_key,:noop_if_exists => true)
        end

        model_handle = user_obj.id_handle().createMH(model_name)
        repo_names = get_all_repos(model_handle).map{|r|r[:repo][:repo_name]}
        unless repo_names.empty?
          RepoManager.set_user_rights_in_repos(username,repo_names,"RW+")
        end
      end
    end

    def remove_user_direct_access(rsa_pub_key)
      user_obj = CurrentSession.new.get_user_object()
      #block called only if key is already there; calls update model at end to be more idempotent
      user_obj.remove_ssh_rsa_pub_key?(rsa_pub_key) do 
        username = user_obj[:username]
        RepoManager.delete_user(username)
        model_handle = user_obj.id_handle().createMH(model_name)
        repo_names = get_all_repos(model_handle).map{|r|r[:repo][:repo_name]}
        unless repo_names.empty?
          RepoManager.remove_user_rights_in_repos(username,repo_names)
        end
      end
    end

    def delete(idh)
      module_obj = idh.create_object()
      unless module_obj.get_target_instances().empty?
        raise ErrorUsage.new("Cannot delete a module if one or more of its target instances exist")
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
        h[r[:id]] ||= r
        h
      end.values
    end

    def remote_already_imported?(library_idh,remote_module_name)
      ret = nil
      sp_hash = {
        :cols => [:id,:display_name],
        :filter => [:and, [:eq, :library_library_id, library_idh.get_id()],
                    [:eq, :remote_repo, remote_module_name]]
      }
      cms = get_objs(library_idh.createMH(model_name),sp_hash)
      not cms.empty?
    end

    def conflicts_with_library_module?(library_idh,module_name)
      sp_hash = {
        :cols => [:id,:display_name],
        :filter => [:and, [:eq, :library_library_id, library_idh.get_id()],
                    [:eq, :display_name, module_name]]
      }
      cms = get_objs(library_idh.createMH(model_name),sp_hash)
      not cms.empty?
    end

    def create_lib_module_and_branch_obj?(library_idh,repo_idh,module_name)
      ref = module_name
      mb_create_hash = ModuleBranch.ret_lib_create_hash(model_name,library_idh,repo_idh)
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
