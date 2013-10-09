module DTK; class AssemblyModule
  class Service < self
    def self.prepare_for_edit(assembly,modification_type)
      service_module = get_service_module(assembly)
      unless modification_type_class = modification_type_class(modification_type)
        raise ErrorUsage.new("Modification type (#{modification_type}) is not supported")
      end
      module_version = ModuleVersion.ret(assembly)
      modification_type_class.create_assembly_branch?(assembly,service_module,module_version)
    end

   private
    def self.get_service_module(assembly)
      unless ret = assembly.get_service_module()
        assembly_name = assembly.display_name_print_form()
        raise ErrorUsage.new("Assembly (#{assembly_name}) is not tied to a service")
      end
      ret
    end

    def self.modification_type_class(modification_type)
      case modification_type
        when :workflow then Workflow
      end
    end

    def self.create_assembly_branch?(assembly,service_module,module_version)
      #TODO: need to decide if we have branch for each modification type or just one per assembly
      #will start with per asembly because looks simpler; also if jump staright into editor we can hide this from end user
      if ret = service_module.get_workspace_branch_info(module_version,:donot_raise_error=>true)
        ret
      end
      create_assembly_branch(assembly,service_module,module_version)
      service_module.get_workspace_branch_info(module_version)
    end

    def self.delete_module?(assembly)
      service_module = get_service_module(assembly)
      module_version = ModuleVersion.ret(assembly)
      service_module.delete_version?(module_version,:donot_delete_meta=>true)
    end

    def self.create_exact_copy_branch(service_module,module_version,opts={})
      opts = {:donot_update_model_from_dsl=>true,:ret_module_branch=>true}
      service_module.create_new_version(module_version,opts)
      opts[:ret_module_branch]
    end

    class Workflow < self
      def self.create_assembly_branch(assembly,service_module,module_version)
        opts = {:base_version=>service_module.get_field?(:version),:assembly_module=>true}
        exact_copy_branch = create_exact_copy_branch(service_module,module_version,opts)
pp [:exact_copy_branch,exact_copy_branch]
        #TODO: next update the workflow
raise ErrorUsage.new('got here')
#TODO: taken from component        #TODO: very expensive call; will refine
#        component_module.create_new_version(module_version,opts)
      end
    end
  end
end; end
