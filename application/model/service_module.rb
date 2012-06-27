r8_require('service_or_component_module')
module XYZ
  class ServiceModule < Model
    extend ServiceOrComponentModuleClassMixin
    def self.create_library_obj(library_idh,module_name,config_agent_type)
      if conflicts_with_library_module?(library_idh,module_name)
        raise Error.new("Create conflicts with existing library module (#{module_name})")
      end

      repo_obj = create_empty_repo_and_local_clone(library_idh,module_name,config_agent_type,:service_module,:delete_if_exists => true)
      create_service_module_obj?(library_idh,repo_obj.id_handle(),module_name)
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
      version_match_row = rows.find do |r|
        if version.nil?
          r[:module_branch][:version].nil?
        else
          r[:module_branch][:version] == version
        end
      end
      version_match_row && version_match_row[:module_branch]
    end

    private
    def self.create_service_module_obj?(library_idh,repo_idh,module_name)
      ref = module_name
      create_hash = {
        "service_module" => {
          ref => {
            :display_name => module_name,
            :module_branch => ModuleBranch.ret_create_hash(library_idh,repo_idh)
          }
        }
      }
      create_from_hash(library_idh,create_hash)
    end
  end
end
