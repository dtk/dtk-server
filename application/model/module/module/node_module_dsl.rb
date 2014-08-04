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

    def self.parse_and_update_model(node_module,impl_obj,module_branch_idh,version=nil,opts={})
      # get associated assembly templates before do any updates and use this to see if any referential integrity
      # problems within transaction after do update; transaction is aborted if any errors found
      Transaction do
        node_module_dsl_obj = create_dsl_object_from_impl(impl_obj, opts)
        raise node_module_dsl_obj if ParsingError.is_error?(node_module_dsl_obj)

        update_opts = {:override_attrs => {"module_branch_id" => module_branch_idh.get_id()}}
        update_opts.merge!(:version => version) if version
        node_module_dsl_obj.update_model(update_opts)
      end
    end

    # creates a ModuleDSL if file_obj_hash is a dtk meta file
    def self.create_from_file_obj_hash?(target_impl,dsl_filename,content,opts={})
      container_idh = opts[:container_idh]
      return nil unless isa_dsl_filename?(dsl_filename)
      parsed_name = parse_dsl_filename(dsl_filename)
      module_branch_idh = target_impl.get_module_branch().id_handle()
      opts[:file_path] = dsl_filename
      input_hash = convert_to_hash(content,parsed_name[:format_type],opts)
      return input_hash if ParsingError.is_error?(input_hash)
      ParsingError.trap do
        new(target_impl.id_handle(),module_branch_idh,input_hash,container_idh)
      end
    end
   private
    def initialize(impl_idh,module_branch_idh,version_specific_input_hash,container_idh=nil)
      @input_hash = version_parse_check_and_normalize(version_specific_input_hash)
      @impl_idh = impl_idh
      @container_idh = container_idh||impl_idh.get_parent_id_handle_with_auth_info()
    end
    
    def version_parse_check_and_normalize(version_specific_input_hash)
      super
      raise Error.new
    end
  end
end

