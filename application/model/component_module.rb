module XYZ
  class ComponentModule < Model
    def self.import(library_idh,remote_module_name)
      module_name = remote_module_name
      if remote_already_imported?(library_idh,remote_module_name)
        raise Error.new("Cannot import remote repo (#{remote_module_name}) which has been imported already")
      end
      if conflict_with_local_repo?(library_idh,module_name)
        raise Error.new("Import conflicts with local repo (#{module_name})")
      end

      #TODO: this might be done a priori
      Repo::Remote.authorize_dtk_instance(remote_module_name)

      #create empty repo on local repo manager; 
      config_agent_type = :puppet #TODO: hard wired
      #need to make sure that tests above indicate whether module exists already since using :delete_if_exists
      repo_obj = create_empty_repo(library_idh,module_name,config_agent_type,:remote_repo_name => remote_module_name,:delete_if_exists => true)
      repo_obj.synchronize_with_remote_repo()

      impl_obj = Implementation.create_library_impl?(library_idh,repo_obj,module_name,config_agent_type,"master")
      impl_obj.create_file_assets_from_dir_els(repo_obj)

      create_meta_info?(library_idh,impl_obj,repo_obj,config_agent_type)

      #TODO: create component_module and cm_branch objects
      nil
    end

    def self.create_empty_repo(library_idh,module_name,config_agent_type,opts={})
      auth_repo_users = RepoUser.authorized_users(library_idh.createMH(:repo_user))
      repo_user_acls = auth_repo_users.map do |repo_username|
        {
          :repo_username => repo_username,
          :access_rights => "RW+"
        }
      end
      Repo.create_empty_repo(library_idh,module_name,config_agent_type,repo_user_acls,opts)
    end

    private
    def self.remote_already_imported?(library_idh,remote_module_name)
      ret = nil
      sp_hash = {
        :cols => [:id,:display_name],
        :filter => [:and, [:eq, :library_library_id, library_idh.get_id()],
                    [:eq, :remote_repo, remote_module_name]]
      }
      cms = get_objs(library_idh.createMH(:component_module),sp_hash)
      not cms.empty?
    end

    def self.conflict_with_local_repo?(library_idh,module_name)
      sp_hash = {
        :cols => [:id,:display_name],
        :filter => [:and, [:eq, :library_library_id, library_idh.get_id()],
                    [:eq, :display_name, module_name]]
      }
      cms = get_objs(library_idh.createMH(:component_module),sp_hash)
      not cms.empty?
    end

    def self.create_meta_info?(library_idh,impl_obj,repo_obj,config_agent_type)
      local_dir = repo_obj.update_object!(:local_dir)[:local_dir]
      r8meta_path = "#{local_dir}/r8meta.#{config_agent_type}.yml"
      r8meta_hash = YAML.load_file(r8meta_path)
      add_library_components_from_r8meta(config_agent_type,library_idh,impl_obj.id_handle,r8meta_hash)
    end
  end
end
