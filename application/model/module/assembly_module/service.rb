module DTK; class AssemblyModule
  class Service < self
    def self.prepare_for_edit(assembly,modification_type)
      modification_type_obj = create_modification_type_object(assembly,modification_type)
      modification_type_obj.create_and_update_assembly_branch?()
    end

    def create_and_update_assembly_branch?()
      module_branch = @service_module.get_workspace_matching_version(@module_version) || create_assembly_branch()
      update_assembly_branch(module_branch)
      @service_module.get_workspace_branch_info(@module_version)
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
      def create_assembly_branch(task_action=nil)
        opts = {:base_version=>@service_module.get_field?(:version),:assembly_module=>true}
        create_exact_copy_branch(opts)
      end
      
      def update_assembly_branch(module_branch,task_action=nil)
        opts = Hash.new
        opts.merge!(:task_action => task_action) if task_action
        template_content =  Task::Template::ConfigComponents.get_or_generate_template_content(:assembly,@assembly,opts)
        splice_in_workflow(module_branch,template_content,task_action)
      end

     private
      def self.splice_in_workflow(module_branch,template_content,task_action=nil)
        hash_content = template_content.serialization_form()
        format = ServiceModule.dsl_files_format_type()
        module_branch.serialize_and_save_to_repo(file_path(task_action),hash_content,format)
      end
      def file_path(task_action=nil)
        task_action ||= DefaultTaskAction
        ServiceModule.assembly_workflow_meta_filename_path(@assembly.get_field?(:dispay_name),task_action)
      end
      #TODO: unify this with code on task/template
      DefaultTaskAction = 'converge'
    end
  end
end; end
