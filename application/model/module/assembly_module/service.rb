module DTK; class AssemblyModule
  class Service < self
    def self.prepare_for_edit(assembly)
      service_module = assembly.get_service_module()
      module_version = ModuleVersion.ret(assembly)
      create_assembly_branch?(assembly,service_module,module_version)
      service_module.get_workspace_branch_info(module_version)
    end

    def self.delete_assembly_modules(assembly)
      #TODO: stub
    end
  end
end; end
