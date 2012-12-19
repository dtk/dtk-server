#TODO" unfify with generate_meta and import_export/import by moving these under component_dsl
#TODO: in process of converting 'meta' to 'dsl'

module DTK
  class ComponentDSL
    r8_nested_require('component_dsl','update_model')
    extend UpdateModelClassMixin
    include UpdateModelMixin

    def self.create_dsl_object(module_branch,dsl_integer_version,format_type=nil)
      impl = module_branch.get_implementation()
      unless dsl_filename = filename?(impl,dsl_integer_version,format_type)
        raise Error.new("Cannot find DSL file")
      end
      parsed_name = parse_dsl_filename(dsl_filename)
      format_type ||= parsed_name[:format_type]
      content = RepoManager.get_file_content(dsl_filename,module_branch)
      input_hash = convert_to_hash(content,format_type)
      new(parsed_name[:config_agent_type],impl.id_handle(),module_branch.id_handle(),input_hash)
    end

    def self.create_meta_file_object(source_impl,container_idh=nil,target_impl=nil)
      unless meta_filename = filename?(source_impl)
        raise Error.new("No component meta file found")
      end
      file_obj_hash = {:path => meta_filename,:implementation => source_impl}
      content = RepoManager.get_file_content(file_obj_hash,{:implementation => source_impl})
      target_impl ||= source_impl
      create_from_file_obj_hash?(target_impl,file_obj_hash,content,container_idh)
    end

    #creates a ComponentDSL if file_obj_hash is a r8meta file
    def self.create_from_file_obj_hash?(target_impl,file_obj_hash,content,container_idh=nil)
      filename =  file_obj_hash[:path]
      return nil unless isa_dsl_filename?(filename)
      parsed_name = parse_dsl_filename(dsl_filename)
      module_branch_idh = target_impl.get_module_branch().id_handle()
      input_hash = convert_to_hash(content,parsed_name[:format_type])
      new(parsed_name[:config_agent_type],target_impl.id_handle(),module_branch_idh,input_hash,container_idh)
    end

    #returns array where each element with keys :path,:hash_content
    def migrate(module_name,new_dsl_integer_version,format_type)
      ret = Array.new
      migrate_proc = migrate_processor(module_name,new_dsl_integer_version,input_hash)
      hash_content = migrate_proc.generate_new_version_hash()
      ret << {:path => self.class.dsl_filename(@config_agent_type,format_type,new_dsl_integer_version),:hash_content => hash_content,:format_type => format_type}
      ret
    end

    def self.filename?(impl_obj,dsl_integer_version=nil,format_type=nil)
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
      R8::Config[:dsl][:component][:version][:default].to_i
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

    def migrate_processor(module_name,new_version_integer,input_hash)
      self.class.load_and_return_version_adapter_class(new_version_integer).ret_migrate_processor(@config_agent_type,module_name,input_hash)
    end

    def self.version()
      VersionIntegerToVersion[version_integer()]
    end
   private
    def self.version_integer()
      to_s =~ /V([0-9]+$)/
      $1.to_i
    end
    def version_parse_check_and_normalize(version_specific_input_hash)
      version = version_specific_input_hash["version"]||"not_specified"
      unless version_integer = VersionToVersionInteger[version]
        raise ErrorUsage.new("Illegal version (#{version}) found in meta file")
      end
      klass = self.class.load_and_return_version_adapter_class(version_integer)
      #parse_check raises errors if any errors found
      klass.parse_check(version_specific_input_hash)
      ret = klass.normalize(version_specific_input_hash)
      #version below refers to component version not metafile version
      ret.each_value{|cmp_info|cmp_info["version"] ||= Component.default_version()}
      ret
    end

    def self.dsl_filename(config_agent_type,format_type,dsl_integer_version=nil)
      unless [:puppet,:chef].include?(config_agent_type.to_sym)
        raise Error.new("Illegal config agent type (#{config_agent_type})")
      end
      "#{DSLFilePrefixes[integer_version(dsl_integer_version)]}.#{config_agent_type}.#{TypeToExtension[format_type]}"
    end

    VersionToVersionInteger = {
      "not_specified" => 1,
      "0.9" => 2
    }
    VersionIntegerToVersion = VersionToVersionInteger.inject(Hash.new) do |h,(v,vi)|
      h.merge(vi=>v)
    end

    DSLFilenameRegexp = {
      1 => /^r8meta\.([a-z]+)\.([a-z]+$)/,
      2 => /^r8component\.([a-z]+)\.([a-z]+$)/
    }
    DSLFilePrefixes = {
      1 => "r8meta",
      2 => "r8component"
    }

    VersionsTreated = DSLFilenameRegexp.keys
    ExtensionToType = {
      "yml" => :yaml,
      "json" => :json
    }
    TypeToExtension = ExtensionToType.inject(Hash.new){|h,(k,v)|h.merge(v => k)}

    class << self
      def load_and_return_version_adapter_class(version_integer)
        @cached_adapter_class ||= Hash.new
        return @cached_adapter_class[version_integer] if @cached_adapter_class[version_integer]
        adapter_name = "v#{version_integer.to_s}"
        opts = {
          :class_name => {:adapter_type => "ComponentDSL"},
          :subclass_adapter_name => true
        }
        @cached_adapter_class[version_integer] = DynamicLoader.load_and_return_adapter_class("component_dsl",adapter_name,opts)
      end
     private
      def integer_version(pos_val)
        pos_val ? pos_val.to_i : default_integer_version()
      end

      def isa_dsl_filename?(filename,dsl_integer_version=nil)
        filename =~ DSLFilenameRegexp[integer_version(dsl_integer_version)]
      end

      #returns hash with keys: :config_agent_type,:format_type
      def parse_dsl_filename(filename,dsl_integer_version=nil)
        if filename =~ DSLFilenameRegexp[integer_version(dsl_integer_version)]
          config_agent_type = $1.to_sym
          file_extension = $2
          unless format_type = ExtensionToType[file_extension]
            raise Error.new("illegal file extension #{file_extension}") unless file_extension
          end
          {:config_agent_type => config_agent_type,:format_type => format_type}
        else
          raise Error.new("Component filename (#{filename}) has illegal form")
        end
      end

      def convert_to_hash(content,format_type)
        begin
          Aux.convert_to_hash(content,format_type)
         rescue ArgumentError => e
          raise ErrorUsage.new("Error parsing the component dsl file; #{e.to_s}")
        end
      end

    end
  end
end
