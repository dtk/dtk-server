module DTK
  class ComponentModule
    module ParseToCreateDSLMixin
      #returns empty hash if no dsl field created or instead hash with keys: :path and :content  
      def parse_impl_to_create_dsl(config_agent_type,impl_obj,opts={})
        parsing_error = nil
        render_hash = nil
        begin
          impl_parse = ConfigAgent.parse_given_module_directory(config_agent_type,impl_obj)
          dsl_generator = ComponentDSL::GenerateFromImpl.create()
          #refinement_hash is version neutral form gotten from version specfic dsl_generator
          refinement_hash = dsl_generator.generate_refinement_hash(impl_parse,module_name(),impl_obj.id_handle())
          render_hash = refinement_hash.render_hash_form(opts)
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

#TODO: for testing
      def test_generate_dsl()
        module_branch = get_module_branch_matching_version()
        config_agent_type = :puppet
        impl_obj = module_branch.get_implementation()
        parse_impl_to_create_dsl(config_agent_type,impl_obj)
      end
### end: for testing

    end
  end
end
