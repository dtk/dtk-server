module DTK; class AssemblyModule
  class Service < self
    r8_nested_require('service','workflow')

    def initialize(assembly,opts={})
      super(assembly)
      @assembly_template_name = assembly_template_name?(assembly)
      @service_module = opts[:service_module] || get_service_module(assembly)
      @am_version = assembly_module_version(assembly)
    end
    private :initialize

    # This checks if an assembly specfic branch has been made and returns this otherwise gives teh base branch
    def self.get_assembly_branch(assembly)
      new(assembly).get_assembly_branch()
    end
    def get_assembly_branch()
      module_branches = @service_module.get_module_branches() 
      module_branches.find{|mb|mb.matches_version?(@am_version)} || module_branches.find{|mb|mb.matches_base_version?()}
    end
    def self.get_or_create_assembly_branch(assembly)
       new(assembly).get_or_create_assembly_branch()
    end
    def get_or_create_assembly_branch()
      @service_module.get_module_branch_matching_version(@am_version) || create_assembly_branch()
    end

    # returns a ModuleRepoInfo object
    def self.prepare_for_edit(assembly,modification_type)
      modification_type_obj = create_modification_type_object(assembly,modification_type)
      # trapping any error when using prepare for edit
      modification_type_obj.create_and_update_assembly_branch?(:trap_error=>true)
    end

    def self.finalize_edit(assembly,modification_type,service_module,module_branch,diffs_summary)
      modification_type_obj = create_modification_type_object(assembly,modification_type,:service_module => service_module)
      modification_type_obj.finalize_edit(module_branch,diffs_summary)
    end

    def delete_module?(opts={})
      service_module = get_service_module(@assembly,opts)
      return if service_module == false
      am_version = assembly_module_version()
      service_module.delete_version?(am_version,:donot_delete_meta=>true)
    end

   private
    # returns new module branch
    def create_assembly_branch()
      base_version = @service_module.get_field?(:version) #TODO: is this right; shouldnt version be on branch, not module
      @service_module.create_new_version(base_version,@am_version)
    end

    def assembly_template_name?(assembly)
      if assembly_template = assembly.get_parent()
        assembly_template.get_field?(:display_name)
      else
        assembly_name = assembly.display_name_print_form()
        Log.info("Assembly (#{assembly_name}) is not tied to an assembly template")
        nil
      end
    end

    def self.create_modification_type_object(assembly,modification_type,opts={})
      modification_type_class(modification_type).new(assembly,opts)
    end

    def self.modification_type_class(modification_type)
      case modification_type
        when :workflow then Workflow
        else raise ErrorUsage.new("Modification type (#{modification_type}) is not supported")
      end
    end

    def get_service_module(assembly,opts={})
      unless ret = assembly.get_service_module()
        assembly_name = assembly.display_name_print_form()
        return false if opts[:do_not_raise]
        raise ErrorUsage.new("Assembly (#{assembly_name}) is not tied to a service")
      end
      ret
    end

  end
end; end
