module DTK
  module ServiceOrComponentModuleClassMixin
    def create_empty_repo_and_local_clone(library_idh,module_name,config_agent_type,module_type,opts={})
      auth_repo_users = RepoUser.authorized_users(library_idh.createMH(:repo_user))
      repo_user_acls = auth_repo_users.map do |repo_username|
        {
          :repo_username => repo_username,
          :access_rights => "RW+"
        }
      end
      Repo.create_empty_repo_and_local_clone(library_idh,module_name,config_agent_type,repo_user_acls,module_type,opts)
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

    def self.create_module_and_branch_obj?(library_idh,repo_idh,module_name)
      ref = module_name
      mb_create__hash = ModuleBranch.ret_create_hash(module_name,library_idh,repo_idh)
      create_hash = {
        model_name.to_s => {
          ref => {
            :display_name => module_name,
            :module_branch => mb_create__hash
          }
        }
      }
      #TODO: double check that this returns just one item as opposed to one per child of service_module
      module_id = create_from_hash(library_idh,create_hash).first[:id]
      module_idh = library_idh.createIDH(:id => module_id, :model_name => model_name)
      parent_col = (model_name == :service_module ? ModuleBranch.service_module_id_col() : ModuleBranch.component_module_id_col())
      sp_hash = {
        :cols => [:id,:display_name],
        :filter => [:and, [:eq, parent_col, module_idh.get_id()], [:eq, :ref, mb_create__hash.keys.first]]
      }
      module_branch_idh = get_objs(library_idh.createMH(:module_branch),sp_hash).map{|r|r.id_handle()}.first
      {:module_idh => module_idh,:module_branch_idh => module_branch_idh}
    end
  end
end
