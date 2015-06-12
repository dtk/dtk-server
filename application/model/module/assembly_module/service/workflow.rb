module DTK; class AssemblyModule
  class Service
    class Workflow < self
      def initialize(assembly,opts={})
        super(assembly,opts)
        #  opts[:task_action] can be nil
        @task_action = opts[:task_action]
      end

      # returns a ModuleRepoInfo object
      def create_and_update_assembly_branch?(opts={})
        module_branch = get_or_create_assembly_branch()
        if opts[:trap_error]
          begin
            update_assembly_branch(module_branch)
          rescue => e
            Log.info_pp(["trapped error in create_and_update_assembly_branch",e])
          end
        end
        @service_module.get_workspace_branch_info(@am_version).merge(:edit_file => meta_file_path())
      end

      def finalize_edit(module_branch,diffs_summary)
        parse_errors = nil
        file_path = meta_file_path()
        if diffs_summary.file_changed?(file_path)
          file_content = RepoManager.get_file_content(file_path,module_branch)
          format_type = Aux.format_type(file_path)
          hash_content = Aux.convert_to_hash(file_content,format_type)
          return hash_content if ServiceModule::ParsingError.is_error?(hash_content)
          parse_errors = Task::Template::ConfigComponents.find_parse_errors(hash_content,@assembly)
          Task::Template.create_or_update_from_serialized_content?(@assembly.id_handle(),hash_content,@task_action)
        end
        raise parse_errors if parse_errors
      end

     private
      def update_assembly_branch(module_branch)
        opts = {:serialized_form => true}
        opts.merge!(:task_action => @task_action) if @task_action
        template_content =  Task::Template::ConfigComponents.get_or_generate_template_content(:assembly,@assembly,opts)
        splice_in_workflow(module_branch,template_content)
      end
      
      def splice_in_workflow(module_branch,template_content)
        hash_content = template_content.serialization_form()
        module_branch.serialize_and_save_to_repo?(meta_file_path(),hash_content)
      end

      def meta_file_path()
        ServiceModule.assembly_workflow_meta_filename_path(@assembly_template_name,@task_action||DefaultTaskAction)
      end
      # TODO: unify this with code on task/template
      DefaultTaskAction = 'create'

    end
  end
end; end
