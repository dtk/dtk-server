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

    def self.parse_and_update_model(component_module,impl_obj,module_branch_idh,version=nil,opts={})
      # get associated assembly templates before do any updates and use this to see if any referential integrity
      # problems within transaction after do update; transaction is aborted if any errors found
      ref_integrity_snapshot = RefIntegrity.snapshot_associated_assembly_templates(component_module)
      model_parsed = nil
      Transaction do
        component_dsl_obj = create_dsl_object_from_impl(impl_obj, opts)
        raise component_dsl_obj if ParsingError.is_error?(component_dsl_obj)

        update_opts = {:override_attrs => {"module_branch_id" => module_branch_idh.get_id()}}
        update_opts.merge!(:version => version) if version
        component_dsl_obj.update_model(update_opts)

        ref_integrity_snapshot.raise_error_if_any_violations(opts)
        ref_integrity_snapshot.integrity_post_processing()
      end
    end

    def self.create_dsl_object(module_branch,dsl_integer_version,format_type=nil)
      input_hash = get_dsl_file_hash_content_info(module_branch,dsl_integer_version,format_type)[:hash_content]
      config_agent_type = ret_config_agent_type(input_hash)
      new(config_agent_type,impl.id_handle(),module_branch.id_handle(),input_hash) 
    end

    def self.create_dsl_object_from_impl(source_impl,opts={})
      target_impl = opts[:target_impl]||source_impl
      info = get_dsl_file_raw_content_and_info(source_impl)
      create_from_file_obj_hash?(target_impl,info[:dsl_filename],info[:content],opts)
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

      config_agent_type = ret_config_agent_type(input_hash)
      return config_agent_type if ParsingError.is_error?(config_agent_type)

      ParsingError.trap do
        new(config_agent_type,target_impl.id_handle(),module_branch_idh,input_hash,container_idh)
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

    # returns array where each element with keys :path,:hash_content
    def migrate(module_name,new_dsl_integer_version,format_type)
      ret = Array.new
      migrate_proc = migrate_processor(module_name,new_dsl_integer_version,input_hash)
      hash_content = migrate_proc.generate_new_version_hash()
      ret << {:path => self.class.dsl_filename(@config_agent_type,format_type,new_dsl_integer_version),:hash_content => hash_content,:format_type => format_type}
      ret
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

    attr_reader :input_hash,:config_agent_type
    def initialize(config_agent_type,impl_idh,module_branch_idh,version_specific_input_hash,container_idh=nil)
      @config_agent_type = config_agent_type
      @input_hash = version_parse_check_and_normalize(version_specific_input_hash)
      @impl_idh = impl_idh
      @container_idh = container_idh||impl_idh.get_parent_id_handle_with_auth_info()
      unless [:project,:library].include?(@container_idh[:model_name])
        raise Error.new("Unexpected parent type of implementation object (#{@container_idh[:model_name]})")
      end
    end

    def migrate_processor(module_name,new_integer_version,input_hash)
      self.class.load_and_return_version_adapter_class(new_integer_version).ret_migrate_processor(@config_agent_type,module_name,input_hash)
    end

    def self.version(integer_version=nil)
      integer_version ||= integer_version()
      VersionIntegerToVersion[integer_version]
    end


    # returns parsing_error if parsing error


    # TODO: this might move to a more common area
    def self.convert_attribute_mapping(input_am,base_cmp,dep_cmp,opts={})
      integer_version = 2 #TODO: fix this being hard coded
      klass = load_and_return_version_adapter_class(integer_version)
      klass.convert_attribute_mapping_helper(input_am,base_cmp,dep_cmp,opts)
    end

   private
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

    def self.dsl_filename(config_agent_type,format_type,dsl_integer_version=nil)
      unless [:puppet,:chef].include?(config_agent_type.to_sym)
        raise Error.new("Illegal config agent type (#{config_agent_type})")
      end
      first_part =
        case integer_version(dsl_integer_version)
         when 1
          "r8meta.#{config_agent_type}"
         when 2,3
          "dtk.model"
        else
          raise Error.new("DSL type not treated")
        end
      "#{first_part}.#{TypeToExtension[format_type]}"
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
      "0.9" => 2,
      "0.9.1" => 3
    }
    VersionIntegerToVersion = VersionToVersionInteger.inject(Hash.new) do |h,(v,vi)|
      h.merge(vi=>v)
    end

    DSLFilenameRegexp = {
      1 => /^r8meta\.[a-z]+\.([a-z]+$)/,
      2 => /^dtk\.model\.([a-z]+$)/,
      3 => /^dtk\.model\.([a-z]+$)/
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
          :class_name => {:adapter_type => "ModuleDSL"},
          :subclass_adapter_name => true
        }
        @cached_adapter_class[integer_version] = DynamicLoader.load_and_return_adapter_class("dsl",adapter_name,opts)
      end

      def isa_dsl_filename?(filename,dsl_integer_version=nil)
        filename =~ DSLFilenameRegexp[integer_version(dsl_integer_version)]
      end

     private
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

      def ret_config_agent_type(input_hash)
        return input_hash if ParsingError.is_error?(input_hash)
        if type = input_hash["module_type"]
          case type
           when "puppet_module" then ConfigAgentTypes[:puppet]
           # Part of code to handle new serverspec type of module
           when "serverspec" then ConfigAgentTypes[:serverspec]
           when "test" then ConfigAgentTypes[:test]
           else 
             ParsingError.new("Unexpected module_type (#{type})")
          end
        else
          DefaultConfigAgentType
        end
      end
      ConfigAgentTypes = {
        :puppet => :puppet,
        :serverspec => :serverspec,
        :test => :test
      }
      DefaultConfigAgentType = ConfigAgentTypes[:puppet]

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
