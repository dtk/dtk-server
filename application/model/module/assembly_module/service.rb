module DTK; class AssemblyModule
  class Service < self
    def self.prepare_for_edit(assembly,modification_type)
      modification_type_obj = create_modification_type_object(assembly,modification_type)
      modification_type_obj.create_assembly_branch?()
    end

    def create_assembly_branch?()
      #TODO: need to decide if we have branch for each modification type or just one per assembly
      #will start with per asembly because looks simpler; also if jump staright into editor we can hide this from end user
      if ret = @service_module.get_workspace_branch_info(@module_version,:donot_raise_error=>true)
        ret
      else
        create_assembly_branch()
        service_module.get_workspace_branch_info(@module_version)
      end
    end

   private
    def self.delete_module?(assembly)
      service_module = get_service_module(assembly)
      module_version = ModuleVersion.ret(assembly)
      service_module.delete_version?(module_version,:donot_delete_meta=>true)
    end

    def self.create_modification_type_object(assembly,modification_type)
      modification_type_class(modification_type).new(assembly)
    end

    def initialize(assembly)
      @assembly = assembly
      @service_module = self.class.get_service_module(assembly)
      @module_version = ModuleVersion.ret(assembly)
    end

    def self.modification_type_class(modification_type)
      case modification_type
        when :workflow then Workflow
        else raise ErrorUsage.new("Modification type (#{modification_type}) is not supported")
      end
    end

    def self.get_service_module(assembly)
      unless ret = assembly.get_service_module()
        assembly_name = assembly.display_name_print_form()
        raise ErrorUsage.new("Assembly (#{assembly_name}) is not tied to a service")
      end
      ret
    end

    def create_exact_copy_branch(opts={})
      opts = opts.merge(:donot_update_model_from_dsl=>true,:ret_module_branch=>true)
      @service_module.create_new_version(@module_version,opts)
      opts[:ret_module_branch]
    end

    class Workflow < self
      def create_assembly_branch()
        opts = {:base_version=>@service_module.get_field?(:version),:assembly_module=>true}
        exact_copy_branch = create_exact_copy_branch(opts)
        template_content =  Task::Template::ConfigComponents.get_or_generate_template_content(:assembly,@assembly,opts={})
pp [:template_content,template_content]
raise ErrorUsage.new('got here')

      end
    end
  end
end; end
