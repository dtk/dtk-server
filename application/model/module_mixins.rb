module DTK
  module ModuleMixin
    def get_repos()
      get_objs_uniq(:repos)
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

    def get_library_repo()
      sp_hash = {
        :cols => [:id,:display_name,:library_repo]
      }
      row = get_obj(sp_hash)
      #opportunisticall set display name on module
      self[:display_name] ||= row[:display_name]
      row[:repo]
    end

    #export to remote
    def export()
      repo = get_library_repo()
      module_name = update_object!(:display_name)[:display_name]
      if repo[:remote_repo_name]
        raise ErrorUsage.new("Cannot export module (#{module_name}) because it is currently linked to a remote module")
      end

      #create remote module
      remote_repo_name = Repo::Remote.new.create_module(module_name,module_type())[:git_repo_name]

      #link and push to remote repo
      repo.link_to_remote(remote_repo_name)
      repo.push_to_remote(remote_repo_name)

      #update last for idempotency (i.e., this is idempotent check)
      repo.update(:remote_repo_name => remote_repo_name)
      remote_repo_name
    end
  end

  module ModuleClassMixin
    def list_remotes(model_handle)
      Repo::Remote.new.list_module_qualified_names(module_type())
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
