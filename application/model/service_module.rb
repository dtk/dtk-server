r8_require('service_or_component_module')
module XYZ
  class ServiceModule < Model
    extend ServiceOrComponentModuleClassMixin
    def self.create(library_idh,module_name,config_agent_type)
      if conflicts_with_library_module?(library_idh,module_name)
        raise Error.new("Create conflicts with existing library module (#{module_name})")
      end

      repo_obj = create_empty_repo_and_local_clone(library_idh,module_name,config_agent_type,:service_module,:delete_if_exists => true)
      create_service_module_obj?(library_idh,repo_obj.id_handle(),module_name)
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
