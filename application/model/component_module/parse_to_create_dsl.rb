module DTK
  class ComponentModule
    module ParseToCreateDSLClassMixin
      #only creates dsl file(s) if one does not exist
      #returns empty hash if no dsl field created or instead hash with keys: :path and :content  
      def parse_impl_to_create_dsl?(module_name,config_agent_type,impl_obj)
        ret = Hash.new
        unless ComponentDSL.contains_dsl_file?(impl_obj)
          ret = parse_impl_to_create_dsl(module_name,config_agent_type,impl_obj)
        end
        ret
      end

      #returns a key with created file's :path and :content 
      def parse_impl_to_create_dsl(module_name,config_agent_type,impl_obj)
        parsing_error = nil
        render_hash = nil
        begin
          impl_parse = ConfigAgent.parse_given_module_directory(config_agent_type,impl_obj)
          dsl_generator = ComponentDSL::GenerateFromImpl.create()
          #refinement_hash is neutral form but with version specfic objects fro next phase
          refinement_hash = dsl_generator.generate_refinement_hash(impl_parse,module_name,impl_obj.id_handle())
          render_hash = refinement_hash.render_hash_form()
        rescue ErrorUsage => e
          #parsing_error = ErrorUsage.new("Error parsing #{config_agent_type} files to generate meta data")
          parsing_error = e
        rescue => e
          Log.error_pp([:parsing_error,e,e.backtrace[0..10]])
          raise e
        end
        if render_hash 
          format_type = ComponentDSL.default_format_type()
          content = render_hash.serialize(format_type)
          dsl_filename = ComponentDSL.dsl_filename(config_agent_type,format_type)
          ret = {:path => dsl_filename, :content => content}
        end
        raise parsing_error if parsing_error
        ret
      end

    end

    module ParseToCreateDSLMixin
#TODO: for testing
      def test_generate_dsl()
        module_branch = get_module_branch_matching_version()
        config_agent_type = :puppet
        impl_obj = module_branch.get_implementation()
        self.class.parse_impl_to_create_dsl(module_name(),config_agent_type,impl_obj)
      end
### end: for testing

     private

    #returns hash with keys: :dsl_created, :new_commit_sha
      def parse_impl_to_create_and_push_dsl?(commit_sha,repo_idh,version)
        dsl_created = nil
        config_agent_type = :puppet #TODO: Hard coded
        new_commit_sha = commit_sha
        module_name = module_name()
        project = get_project()
        branch_name = ModuleBranch.workspace_branch_name(project,version)
        repo = repo_idh.create_object()
        impl_obj = Implementation.create_workspace_impl?(project.id_handle(),repo,module_name,config_agent_type,branch_name,version)
        
        if dsl_file_info = self.class.parse_impl_to_create_dsl?(module_name,config_agent_type,impl_obj)
          dsl_created = true
          new_commit_sha = FileAsset.add_and_push_to_repo(impl_obj,type,dsl_file_info[:path],dsl_file_info[:content])
        end
        {:dsl_created => dsl_created,:new_commit_sha => new_commit_sha}
      end

    end
  end
end
