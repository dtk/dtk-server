module DTK
  class ModuleDSL
    r8_nested_require('dsl','parsing_error')
    r8_nested_require('dsl','update_model')
    r8_nested_require('dsl','generate_from_impl')
    r8_nested_require('dsl','object_model_form')
    r8_nested_require('dsl','incremental_generator')
    # TODO: this needs to be after object_model_form, because object_model_form loads errors; should move errors to parent and include first here
    r8_nested_require('dsl','ref_integrity')
    extend UpdateModelClassMixin
    include UpdateModelMixin

    attr_reader :input_hash,:project_idh,:module_branch
    def initialize(impl_idh,module_branch,version_specific_input_hash,opts={})
      @module_branch = module_branch
      @input_hash = version_parse_check_and_normalize(version_specific_input_hash)
      @impl_idh = impl_idh
      @project_idh = impl_idh.get_parent_id_handle_with_auth_info()
      @ref_integrity_snapshot = opts[:ref_integrity_snapshot]
      @component_module = opts[:component_module]
      # TODO: deprecate <config_agent_type>
      @config_agent_type = ConfigAgent::Type.default_symbol
    end
    private :initialize

    def self.parse_dsl(component_module,impl_obj,opts={})
      ref_integrity_snapshot = RefIntegrity.snapshot_associated_assembly_templates(component_module)
      opts_create_dsl = opts.merge(:ref_integrity_snapshot => ref_integrity_snapshot, :component_module => component_module)
      create_dsl_object_from_impl(impl_obj,opts_create_dsl)
    end

    def update_model_with_ref_integrity_check(opts={})
      # get associated assembly templates before do any updates and use this to see if any referential integrity
      # problems within transaction after do update; transaction is aborted if any errors found
      Model.Transaction do
        update_opts = {
          :override_attrs => {"module_branch_id" => @module_branch.id()},
          :namespace      => component_module().module_namespace()
        }
        update_opts.merge!(:version => opts[:version]) if opts[:version]
        update_model(update_opts)

        ref_integrity_snapshot.raise_error_if_any_violations()
        ref_integrity_snapshot.integrity_post_processing()
      end
    end

    # parses and creates dsl_object form file in implementation
    # or content if passed in opts
    def self.create_dsl_object_from_impl(impl_obj,opts={})
      if dsl_created_info =  opts[:dsl_created_info]
        dsl_filename = dsl_created_info[:path]
        content = dsl_created_info[:content]
      else
        info = get_dsl_file_raw_content_and_info(impl_obj)
        dsl_filename = info[:dsl_filename]
        content = info[:content]
      end
      create_from_file_obj_hash(impl_obj,dsl_filename,content,opts)
    end
    # parses and creates dsl_object form hash parsed in as target
    def self.create_from_file_obj_hash(impl_obj,dsl_filename,content,opts={})
      unless isa_dsl_filename?(dsl_filename)
        raise Error.new("The file path (#{dsl_filename}) does not refer to a dsl file name")
      end
      parsed_name = parse_dsl_filename(dsl_filename)
      opts[:file_path] = dsl_filename
      input_hash = convert_to_hash(content,parsed_name[:format_type],opts)
      return input_hash if ParsingError.is_error?(input_hash)

      name_attribute_check = name_attribute_integrity_check(input_hash['components'])
      return name_attribute_check if ParsingError.is_error?(name_attribute_check)

      ParsingError.trap do
        module_branch = impl_obj.get_module_branch()
        new(impl_obj.id_handle(),module_branch,input_hash,opts)
      end
    end

    # returns [dsl_file_path,hash_content,fragment_hash]
    def self.incremental_generate(module_branch,augmented_objects,context={})
      augmented_objects = [augmented_objects] unless augmented_objects.kind_of?(Array)
      helper = IncrementalGeneratorHelper.new(augmented_objects)
      info = get_dsl_file_hash_content_info(module_branch)
      full_hash = info[:hash_content]
      fragment_hash = helper.update_full_hash!(full_hash,augmented_objects,context)
      [info[:dsl_filename],full_hash,fragment_hash]
    end

    def self.contains_dsl_file?(impl_obj,dsl_integer_version=nil,format_type=nil)
      dsl_integer_version ||= integer_version(dsl_integer_version)
      unless regexp = DSLFilenameRegexp[dsl_integer_version]
        raise Error.new("Do not treat Component DSL version: #{dsl_integer_version.to_s}")
      end
      format_ext_regexp = (format_type && Regexp.new("\.(#{ExtensionToType[format_type.to_sym]}$)"))
      depth = 1
      RepoManager.ls_r(depth,{:file_only => true},impl_obj).find do |f|
        (f =~ regexp) and (format_ext_regexp.nil? or f =~ format_ext_regexp)
      end
    end

    def self.default_integer_version()
      R8::Config[:dsl][:component][:integer_version][:default].to_i
    end

    def self.default_format_type()
      R8::Config[:dsl][:component][:format_type][:default].to_sym
    end

    def self.version(integer_version=nil)
      integer_version ||= integer_version()
      VersionIntegerToVersion[integer_version]
    end

    def self.name_attribute_integrity_check(components)
      return unless components
      names = []

      components.each do |name,value|
        # if component is 'puppet definition'
        if (value['external_ref']||{}).has_key?('puppet_definition')
          attributes = value['attributes']
          names = get_name_attributes(attributes)
          return ParsingError::BadPuppetDefinition.new(:component => name, :invalid_names => names) unless names.size == 1
          # if names.size == 1
            # return ParsingError::BadPuppetDefinition.new(:component => name, :missing_req_or_def => missing_req_or_def) unless missing_req_or_def.empty?
          # else
            # return ParsingError::BadPuppetDefinition.new(:component => name, :invalid_names => names)
          # end
        end
      end
    end

    def self.get_name_attributes(attributes)
      names = []
      return names unless attributes

      attributes.each do |n_name, n_attr|
        if n_name.eql?('name')
          names << n_name
          # missing_req_or_def << n_name unless (n_attr.has_key?('required') || n_attr.has_key?('default'))
        elsif ext_ref = n_attr['external_ref']
          names << n_name if (ext_ref.has_key?('puppet_attribute') && ext_ref['puppet_attribute'].eql?('name'))
        end
      end
      return names
    end
    # returns parsing_error if parsing error

    # TODO: this might move to a more common area
    def self.convert_attribute_mapping(input_am,base_cmp,dep_cmp,opts={})
      integer_version = 2 #TODO: fix this being hard coded
      klass = load_and_return_version_adapter_class(integer_version)
      klass.convert_attribute_mapping_helper(input_am,base_cmp,dep_cmp,opts)
    end

   private
    def ref_integrity_snapshot()
      unless @ref_integrity_snapshot
        raise Error.new("Unexpected that @ref_integrity_snapshot is nil")
      end
      @ref_integrity_snapshot
    end

    def component_module()
      unless @component_module
        raise Error.new("Unexpected that @component_module is nil")
      end
      @component_module
    end

    class IncrementalGeneratorHelper < self
      def initialize(augmented_objects)
        @object_class = object_class(augmented_objects)

        integer_version = self.class.default_integer_version()
        base_klass = self.class.load_and_return_version_adapter_class(integer_version)
        @version_klass = base_klass.const_get('IncrementalGenerator')
      end

      def update_full_hash!(full_hash,augmented_objects,context={})
        fragment_hash = get_config_fragment_hash_form(augmented_objects)
        merge_fragment_into_full_hash!(full_hash,@object_class,fragment_hash,context)
        fragment_hash
      end

      def get_config_fragment_hash_form(augmented_objects)
        augmented_objects.inject(Hash.new) do |h,aug_obj|
          generated_hash = @version_klass.generate(aug_obj)
          h.merge(generated_hash)
        end
      end

      def merge_fragment_into_full_hash!(full_hash,object_class,fragment,context={})
        @version_klass.merge_fragment_into_full_hash!(full_hash,object_class,fragment,context)
        full_hash
      end

      def object_class(augmented_objects)
        object_classes = augmented_objects.map{|obj|obj.class}.uniq
        unless object_classes.size == 1
          object_classes_print_form = object_classes.map{|r|r.to_s}.join(',')
          raise Error.new("augmented_objects must have the same type rather than (#{object_classes_print_form})")
        end
        object_classes.first
      end
    end

    def self.get_dsl_file_hash_content_info(impl_or_module_branch_obj,dsl_integer_version=nil,format_type=nil)
      impl_obj =
        if impl_or_module_branch_obj.kind_of?(Implementation)
          impl_or_module_branch_obj
        elsif impl_or_module_branch_obj.kind_of?(ModuleBranch)
          impl_or_module_branch_obj.get_implementation()
        else raise Error.new("Unexpected object type for impl_or_module_branch_obj (#{impl_or_module_branch_obj.class})")
        end
      info = get_dsl_file_raw_content_and_info(impl_obj,dsl_integer_version,format_type)
      {:hash_content => convert_to_hash(info[:content],info[:format_type])}.merge(Aux::hash_subset(info,[:format_type,:dsl_filename]))
    end

    def self.get_dsl_file_raw_content_and_info(impl_obj,dsl_integer_version=nil,format_type=nil)
      unless dsl_filename = contains_dsl_file?(impl_obj,dsl_integer_version,format_type)
        raise Error.new("Cannot find DSL file")
      end
      parsed_name = parse_dsl_filename(dsl_filename,dsl_integer_version)
      format_type ||= parsed_name[:format_type]
      content = RepoManager.get_file_content(dsl_filename,:implementation => impl_obj)
      {:content => content,:format_type => format_type,:dsl_filename => dsl_filename}
    end

    def version_parse_check_and_normalize(version_specific_input_hash)
      integer_version = integer_version(version_specific_input_hash)
      klass = self.class.load_and_return_version_adapter_class(integer_version)
      # parse_check raises errors if any errors found
      klass.parse_check(version_specific_input_hash)
      ret = klass.normalize(version_specific_input_hash)
      # version below refers to component version not metafile version
      ret.each_value{|cmp_info|cmp_info["version"] ||= Component.default_version()}
      ret
    end

    def self.dsl_filename(format_type,dsl_integer_version=nil)
      first_part = 'dtk.model'
      unless extension = TypeToExtension[format_type]
        legal_types = TypeToExtension.values.uniq.join(',')
        raise Error.new("Illegal dsl_filename extension (#{format_type}); legal types are: #{legal_types}")
      end
      "#{first_part}.#{extension}"
    end

    def integer_version(version_specific_input_hash)
      version = version_specific_input_hash["dsl_version"]
      unless integer_version = (version ? VersionToVersionInteger[version.to_s] : VersionIntegerWhenVersionMissing)
        raise ErrorUsage.new("Illegal version (#{version}) found in meta file")
      end
      integer_version
    end
    VersionIntegerWhenVersionMissing = 1
    VersionToVersionInteger = {
      "0.9"   => 2,
      "0.9.1" => 3,
      "1.0.0" => 4
    }
    VersionIntegerToVersion = VersionToVersionInteger.inject(Hash.new) do |h,(v,vi)|
      h.merge(vi=>v)
    end

    DSLFilenameRegexp = {
      1 => /^r8meta\.[a-z]+\.([a-z]+$)/,
      2 => /^dtk\.model\.([a-z]+$)/,
      3 => /^dtk\.model\.([a-z]+$)/,
      4 => /^dtk\.model\.([a-z]+$)/,
    }

    VersionsTreated = DSLFilenameRegexp.keys
    ExtensionToType = {
      "yaml" => :yaml,
      "json" => :json
    }
    TypeToExtension = ExtensionToType.inject(Hash.new){|h,(k,v)|h.merge(v => k)}

    class << self
      def load_and_return_version_adapter_class(integer_version)
        @cached_adapter_class ||= Hash.new
        return @cached_adapter_class[integer_version] if @cached_adapter_class[integer_version]
        adapter_name = "v#{integer_version.to_s}"
        opts = {
          :class_name => {:adapter_type => adapter_type()},
          :subclass_adapter_name => true
        }
        @cached_adapter_class[integer_version] = DynamicLoader.load_and_return_adapter_class(adapter_dir(),adapter_name,opts)
      end

      def isa_dsl_filename?(filename,dsl_integer_version=nil)
        filename =~ DSLFilenameRegexp[integer_version(dsl_integer_version)]
      end

     private
      def adapter_type()
        "ModuleDSL"
      end
      def adapter_dir()
        "dsl"
      end

      def Transaction(*args,&block)
        Model.Transaction(*args,&block)
      end

      def integer_version(pos_val=nil)
        pos_val ? pos_val.to_i : default_integer_version()
      end

      # returns hash with keys: :format_type
      def parse_dsl_filename(filename,dsl_integer_version=nil)
        if filename =~ DSLFilenameRegexp[integer_version(dsl_integer_version)]
          file_extension = $1
          unless format_type = ExtensionToType[file_extension]
            raise Error.new("illegal file extension #{file_extension}")
          end
          {:format_type => format_type}
        else
          raise Error.new("Component filename (#{filename}) has illegal form")
        end
      end

      # TODO: deprecate <config_agent_type>
      def ret_config_agent_type(input_hash)
        return input_hash if ParsingError.is_error?(input_hash)
        if type = input_hash["module_type"]
          case type
           when "puppet_module" then ConfigAgent::Type::Symbol.puppet
           # Part of code to handle new serverspec type of module
           when "serverspec" then ConfigAgent::Type::Symbol.serverspec
           when "test" then ConfigAgent::Type::Symbol.test
           when "node_module" then ConfigAgent::Type::Symbol.node_module
           else
             ParsingError.new("Unexpected module_type (#{type})")
          end
        else
          ConfigAgent::Type.default_symbol()
        end
      end

      def convert_to_hash(content,format_type,opts={})
        begin
          Aux.convert_to_hash(content,format_type,opts)
         rescue ArgumentError => e
          raise ErrorUsage.new("Error parsing the component dsl file; #{e.to_s}")
        end
      end

    end
  end
end
