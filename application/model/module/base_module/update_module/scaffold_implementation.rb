# TODO: Marked for removal [Haris]
module DTK; class BaseModule; class UpdateModule
  module ScaffoldImplementation
    # Rich: DTK-1754 pass in an (optional) option that indicates scaffolding strategy
    # will build in flexibility to support a number of varaints in how Puppet as an example
    # gets mapped to a starting point dtk.model.yaml file
    # Initially we wil hace existing stargey for the top level and
    # completely commented out for the component module dependencies
    # As we progress we can identiy two pieces of info
    # 1) what signatures get parsed (e.g., only top level puppet ones) and put in dtk
    # 2) what signatures get parsed and put in commented out
    def self.create_dsl(module_name, config_agent_type, impl_obj, opts = {})
      ret = ModuleDSLInfo::CreatedInfo.new()
      parsing_error = nil
      render_hash = nil
      begin
        impl_parse = ConfigAgent.parse_given_module_directory(config_agent_type, impl_obj)
        dsl_generator = ModuleDSL::GenerateFromImpl.create()
        # refinement_hash is version neutral form gotten from version specfic dsl_generator
        refinement_hash = dsl_generator.generate_refinement_hash(impl_parse, module_name, impl_obj.id_handle())
        render_hash = refinement_hash.render_hash_form(opts)
       rescue ErrorUsage => e
        # parsing_error = ErrorUsage.new("Error parsing #{config_agent_type} files to generate meta data")
        parsing_error = e
       rescue => e
        Log.error_pp([:parsing_error, e, e.backtrace[0..10]])
        raise e
      end
      if render_hash
        format_type = ModuleDSL.default_format_type()
        content = render_hash.serialize(format_type)
        dsl_filename = ModuleDSL.dsl_filename(format_type)
        ret.merge!(path: dsl_filename, content: content)
        if opts[:ret_hash_content]
          ret.merge!(hash_content: render_hash)
        end
      end
      raise parsing_error if parsing_error
      ret
    end
  end
end; end; end
