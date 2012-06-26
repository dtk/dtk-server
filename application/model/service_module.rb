r8_require('service_or_component_module')
module XYZ
  class ServiceModule < Model
    extend ServiceOrComponentModuleClassMixin
    def self.create(library_idh,module_name,config_agent_type)
      if conflict_with_local_repo?(library_idh,module_name)
        raise Error.new("Import conflicts with existing repo (#{module_name})")
      end

      repo_obj = create_empty_repo(library_idh,module_name,config_agent_type,:delete_if_exists => true)

      #TODO: create service_module and sm_branch objects
      nil
    end
  end
end
