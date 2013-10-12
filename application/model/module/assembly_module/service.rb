module DTK; class AssemblyModule
  class Service < self
    def self.prepare_for_edit(assembly,modification_type)
      modification_type_obj = create_modification_type_object(assembly,modification_type)
      modification_type_obj.create_and_update_assembly_branch?()
    end

    def self.finalize_edit(assembly,modification_type,service_module,module_branch,diffs_summary)
      modification_type_obj = create_modification_type_object(assembly,modification_type,:service_module => service_module)
      modification_type_obj.finalize_edit(module_branch,diffs_summary)
    end

    def create_and_update_assembly_branch?()
      module_branch = @service_module.get_module_branch_matching_version(@module_version) || create_assembly_branch()
      update_assembly_branch(module_branch)
      @service_module.get_workspace_branch_info(@module_version)
    end

   private
    def self.delete_module?(assembly)
      service_module = get_service_module(assembly)
      module_version = ModuleVersion.ret(assembly)
      service_module.delete_version?(module_version,:donot_delete_meta=>true)
    end

    def self.create_modification_type_object(assembly,modification_type,opts={})
      modification_type_class(modification_type).new(assembly,opts)
    end

    def initialize(assembly,opts={})
      @assembly = assembly
      @assembly_template_name = assembly_template_name(assembly)
      @service_module = opts[:service_module] || self.class.get_service_module(assembly)
      @module_version = ModuleVersion.ret(assembly)
    end

    def assembly_template_name(assembly)
      unless assembly_template = assembly.get_parent()
        assembly_name = assembly.display_name_print_form()
        raise ErrorUsage.new("Assembly (#{assembly_name}) is not tied to an assembly template")
      end
      assembly_template.get_field?(:display_name)
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

      def finalize_edit(module_branch,diffs_summary,task_action=nil)
        file_path = file_path(task_action)
        if diffs_summary.file_changed?(file_path)
          file_content = RepoManager.get_file_content(file_path,module_branch)
          format_type = Aux.format_type(file_path)
          hash_content = Aux.convert_to_hash(file_content,format_type)
          return hash_content if hash_content.is_a?(ErrorUsage::DSLParsing)
          #TODO: put in parsing check of the task template
          Task::Template.create_or_update_from_serialized_content?(@assembly.id_handle(),hash_content,task_action)
          nil
        end
      end

     private
      def splice_in_workflow(module_branch,template_content,task_action=nil)
        hash_content = template_content.serialization_form()
        module_branch.serialize_and_save_to_repo(file_path(task_action),hash_content)
      end
      def file_path(task_action=nil)
        task_action ||= DefaultTaskAction
        ServiceModule.assembly_workflow_meta_filename_path(@assembly_template_name,task_action)
      end
      #TODO: unify this with code on task/template
      DefaultTaskAction = 'converge'
    end
  end
end; end
