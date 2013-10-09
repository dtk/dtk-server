module DTK; class AssemblyModule
  class Service < self
    def self.prepare_for_edit(assembly,modification_type)
      unless modification_type_class = modification_type_class(modification_type)
        raise ErrorUsage.new("Modification type (#{modification_type}) is not supported")
      end
      unless service_module = assembly.get_service_module()
        assembly_name = assembly.display_name_print_form()
        raise ErrorUsage.new("Assembly (#{assembly_name}) is not tied to a service")
      end
      module_version = ModuleVersion.ret(assembly)
      modification_type_class.create_assembly_branch?(assembly,service_module,module_version)
    end

   private
    def self.modification_type_class(modification_type)
      case modification_type
        when :workflow then Workflow
      end
    end

    def self.create_assembly_branch?(assembly,service_module,module_version)
      if ret = service_module.get_workspace_branch_info(module_version,:donot_raise_error=>true)
        ret
      end
      create_assembly_branch(assembly,service_module,module_version)
      service_module.get_workspace_branch_info(module_version)
    end

    def self.delete_assembly_modules(assembly)
      #TODO: stub
    end

    class Workflow < self
      def self.create_assembly_branch(assembly,service_module,module_version)
        opts = {:base_version=>service_module.get_field?(:version),:assembly_module=>true}
raise ErrorUsage.new('got here')
#TODO: taken from component        #TODO: very expensive call; will refine
#        component_module.create_new_version(module_version,opts)
      end
    end
  end
end; end
