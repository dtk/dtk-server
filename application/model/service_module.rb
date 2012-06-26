r8_require('service_or_component_module')
module XYZ
  class ServiceModule < Model
    extend ServiceOrComponentModuleClassMixin
    def self.create(library_idh,module_name,config_agent_type)
      if conflicts_with_library_module?(library_idh,module_name)
        raise Error.new("Import conflicts with existing library module (#{module_name})")
      end

      repo_obj = create_empty_repo_and_local_clone(library_idh,module_name,config_agent_type,:service_module,:delete_if_exists => true)
      create_service_module_obj?(library_idh,module_name)
    end
    private
    def self.create_service_module_obj?(library_idh,module_name)
      ref = module_name
      assigns = {
        :display_name => module_name,
        :library_library_id => library_idh.get_id()
      }
      create_from_row?(library_idh.createMH(model_name),ref,assigns)
    end
  end
end
