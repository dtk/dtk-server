r8_require('service_or_component_module')
module DTK
  class ServiceModule < Model
    extend ServiceOrComponentModuleClassMixin
    #export to remote
    def export()
      repo = get_library_repo()
      module_name = update_object!(:display_name)[:display_name]
      if repo[:remote_repo_name]
        raise ErrorUsage.new("Cannot export service module (#{module_name}) because it is has been exported already")
      end

      #create remote repo
      Repo::Remote.create_repo(module_name)

      #link and push to remote repo
      #TODO: remote_repo_name might isnated be something like "sm-#{module_name}"
      remote_repo_name = module_name
      repo.link_to_remote(remote_repo_name)
      repo.push_to_remote(remote_repo_name)

      #update last for idempotency
      repo.update(:remote_repo_name => remote_repo_name)
      remote_repo_name
    end

    def list_assemblies()
      sp_hash = {
        :cols => [:module_branches]
      }
      mb_idhs = get_objs(sp_hash).map{|r|r[:module_branch].id_handle()}
      Assembly.list_from_library(model_handle(:component),:module_branch_idhs => mb_idhs)
    end

    def self.create_library_obj(library_idh,module_name,config_agent_type)
      if conflicts_with_library_module?(library_idh,module_name)
        raise Error.new("Create conflicts with existing library module (#{module_name})")
      end

      repo_obj = create_empty_repo_and_local_clone(library_idh,module_name,config_agent_type,:service_module,:delete_if_exists => true)
      module_and_branch_idhs = create_lib_module_and_branch_obj?(library_idh,repo_obj.id_handle(),module_name)
      module_and_branch_idhs[:module_idh]
    end

    def self.get_module_branch(library_idh,service_module_name,version=nil)
      sp_hash = {
        :cols => [:id,:display_name,:module_branches],
        :filter => [:and, [:eq, :display_name, service_module_name], [:eq, :library_library_id, library_idh.get_id()]]
      }
      rows =  get_objs(library_idh.create_childMH(:service_module),sp_hash)
      if rows.empty?
        raise Error.new("Service module (#{service_module_name}) does not exist")
      end
      version ||= BranchNameDefaultVersion
      version_match_row = rows.find{|r|r[:module_branch][:version] == version}
      version_match_row && version_match_row[:module_branch]
    end
   private
    def get_library_repo()
      sp_hash = {
        :cols => [:id,:display_name,:library_repo]
      }
      row = get_obj(sp_hash)
      #opportunisticall set display name on service_module
      self[:display_name] ||= row[:display_name]
      row[:repo]
    end
  end
end
