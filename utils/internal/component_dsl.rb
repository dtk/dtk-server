#TODO" unfify with generate_meta and import_export/import by moving these under component_dsl
module DTK
  class ComponentDSL
    r8_nested_require('component_dsl','update_model')
    extend UpdateModelClassMixin
    include UpdateModelMixin

    def self.create_dsl_object(module_branch,dsl_integer_version,format_type)
      impl = module_branch.get_implementation()
      unless dsl_filename = filename_if_exists?(impl,dsl_integer_version,format_type)
        raise Error.new("Cannot find DSL file")
      end
      config_agent_type,file_extension = parse_meta_filename(dsl_filename)
      content = RepoManager.get_file_content(dsl_filename,module_branch)
      input_hash = convert_to_hash(format_type,content)
      new(config_agent_type,impl.id_handle(),module_branch.id_handle(),input_hash)
    end

    attr_reader :input_hash
    def initialize(config_agent_type,impl_idh,module_branch_idh,version_specific_input_hash,container_idh=nil)
      @config_agent_type = config_agent_type
      @input_hash = version_parse_check_and_normalize(version_specific_input_hash)
      @impl_idh = impl_idh
      @container_idh = container_idh||impl_idh.get_parent_id_handle_with_auth_info()
      unless [:project,:library].include?(@container_idh[:model_name])
        raise Error.new("Unexpected parent type of implementation object (#{@container_idh[:model_name]})")
      end
    end

    class << self
     private
      def filename_if_exists?(impl_obj,dsl_integer_version=1,format_type=nil)
        unless regexp = DSLFilenameRegexp[dsl_integer_version]
          raise Error.new("Do not treat Component DSL version: #{dsl_integer_version.to_s}")
        end
        format_ext_regexp = (format_type && Regexp.new("\.(#{ExtensionToType[format_type.to_sym]}$)"))
        depth = 1
        RepoManager.ls_r(depth,{:file_only => true},impl_obj).find do |f|
          (f =~ regexp) and (format_ext_regexp.nil? or f =~ format_ext_regexp)
        end
      end
      #returns [config_agent_type,file_extension]
      def isa_dsl_filename?(filename,dsl_integer_version=1)
        filename =~ DSLFilenameRegexp[dsl_integer_version]
      end
      def parse_dsl_filename(filename,dsl_integer_version=1)
        if filename =~ DSLFilenameRegexp[dsl_integer_version]
          [$1.to_sym,$2]
        else
          raise Error.new("Component filename (#{filename}) has illegal form")
        end
      end
    end
    DSLFilenameRegexp = {
      1 => /^r8meta\.([a-z]+)\.([a-z]+$)/,
      2 => /^r8component\.([a-z]+)\.([a-z]+$)/
    }
    VersionsTreated = DSLFilenameRegexp.keys
    ExtensionToType = {
      "yml" => :yaml,
      "json" => :json
    }
    TypeToExtension = ExtensionToType.inject(Hash.new){|h,(k,v)|h.merge(v => k)}

    #TODO: may be deprecating some of below
    def self.create_meta_file_object(source_impl,container_idh=nil,target_impl=nil)
      unless meta_filename = filename_if_exists?(source_impl)
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
      config_agent_type,file_extension = parse_dsl_filename(filename)
      format_type = ExtensionToType[file_extension]
      raise Error.new("illegal file extension #{file_extension}") unless file_extension
      module_branch_idh = target_impl.get_module_branch().id_handle()
      input_hash = convert_to_hash(format_type,content)
      self.new(config_agent_type,target_impl.id_handle(),module_branch_idh,input_hash,container_idh)
    end

    def self.filename(config_agent_type)
      unless [:puppet,:chef].include?(config_agent_type.to_sym)
        raise Error.new("Illegal config agent type (#{config_agent_type})")
      end
      "r8meta.#{config_agent_type}.yml"
    end

    def self.migrate_processor(module_name,new_version_integer,old_version_hash)
      load_and_return_version_adapter_class(new_version_integer).ret_migrate_processor(module_name,old_version_hash)
    end

    def self.version()
      VersionIntegerToVersion[version_integer()]
    end
    def self.version_integer()
      to_s =~ /V([0-9]+$)/
      $1.to_i
    end

   private
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
    VersionToVersionInteger = {
      "not_specified" => 1,
      "0.9" => 2
    }
    VersionIntegerToVersion = VersionToVersionInteger.inject(Hash.new) do |h,(v,vi)|
      h.merge(vi=>v)
    end

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

      def convert_to_hash(format_type,content)
        case format_type
        when :yaml then 
          convert_to_hash_yaml(content)
        else
          raise Error.new("cannot treat format type #{format_type}")
        end
      end

      def convert_to_hash_yaml(content)
        #TODO: see if ArgumentError catches all errors
        begin
          YAML.load(content)
         rescue ArgumentError => e
          raise ErrorUsage.new("Error parsing the r8 meta file; #{e.to_s}")
        end
      end
    end
  end
end
