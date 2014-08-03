module DTK
  class NodeModuleDSL < ModuleDSL
    # r8_nested_require('dsl','parsing_error')
    # r8_nested_require('dsl','update_model')
    # r8_nested_require('dsl','generate_from_impl')
    # r8_nested_require('dsl','object_model_form')
    # r8_nested_require('dsl','incremental_generator')
    # TODO: this needs to be after object_model_form, because object_model_form loads errors; should move errors to parent and include first here
    # r8_nested_require('dsl','ref_integrity')
    # extend UpdateModelClassMixin
    # include UpdateModelMixin

    # creates a ModuleDSL if file_obj_hash is a dtk meta file
    def self.create_from_file_obj_hash?(target_impl,dsl_filename,content,opts={})
      container_idh = opts[:container_idh]
      return nil unless isa_dsl_filename?(dsl_filename)
      parsed_name = parse_dsl_filename(dsl_filename)
      module_branch_idh = target_impl.get_module_branch().id_handle()
      opts[:file_path] = dsl_filename
      input_hash = convert_to_hash(content,parsed_name[:format_type],opts)

      return input_hash if ModuleDSL::ParsingError.is_error?(input_hash)

      config_agent_type = ret_config_agent_type(input_hash)
      return config_agent_type if ModuleDSL::ParsingError.is_error?(config_agent_type)

      puts "-----------------------------------------------------"
      pp input_hash
      puts "-----------------------------------------------------"

      raise Error.new("For Rich. Need to implement mechanism that will create objects from 'input_hash'")
      # ModuleDSL::ParsingError.trap do
      #   new(config_agent_type,target_impl.id_handle(),module_branch_idh,input_hash,container_idh)
      # end
    end

  end
end

