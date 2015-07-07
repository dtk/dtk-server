# TODO: this needs to be updated after refactor to parse_and_update_model
module DTK
  class NodeModuleDSL < ModuleDSL
    r8_nested_require('node_module_dsl','update_model')
    include UpdateModelMixin

    def self.parse_and_update_model(_node_module,impl_obj,module_branch_idh,version=nil,opts={})
      # get associated assembly templates before do any updates and use this to see if any referential integrity
      # problems within transaction after do update; transaction is aborted if any errors found
      Transaction do
        node_module_dsl_obj = create_dsl_object_from_impl(impl_obj, opts)
        raise node_module_dsl_obj if ParsingError.is_error?(node_module_dsl_obj)

        update_opts = {override_attrs: {"module_branch_id" => module_branch_idh.get_id()}}
        update_opts.merge!(version: version) if version
        node_module_dsl_obj.update_model(update_opts)
      end
    end

    # creates a ModuleDSL if file_obj_hash is a dtk meta file
    def self.create_from_file_obj_hash(target_impl,dsl_filename,content,opts={})
      container_idh = opts[:container_idh]
      return nil unless isa_dsl_filename?(dsl_filename)
      parsed_name = parse_dsl_filename(dsl_filename)
      module_branch_idh = target_impl.get_module_branch().id_handle()
      opts[:file_path] = dsl_filename
      input_hash = convert_to_hash(content,parsed_name[:format_type],opts)
      return input_hash if ParsingError.is_error?(input_hash)
      ParsingError.trap do
        new(target_impl.id_handle(),input_hash,module_branch_idh,container_idh)
      end
    end

    private

    def initialize(impl_idh,version_specific_input_hash,module_branch_idh,container_idh)
      @input_hash = version_parse_check_and_normalize(version_specific_input_hash)
      @impl_idh = impl_idh
      @module_branch_idh = module_branch_idh
      @container_idh = container_idh
    end

    # There is just one version now for node modules
    IntegerVersion = 1
    def version_parse_check_and_normalize(version_specific_input_hash)
      klass = self.class.load_and_return_version_adapter_class(IntegerVersion)
      # parse_check raises errors if any errors found
      klass.parse_check(version_specific_input_hash)
      klass.normalize(version_specific_input_hash)
    end
    # Set for load_and_return_version_adapter_class
    def self.adapter_type
      "NodeModuleDSL"
    end
    def self.adapter_dir
      "node_module_dsl"
    end
  end
end

