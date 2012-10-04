#TODO" unfify with generate_meta and import_export/import by moving these under component_meta_file
r8_nested_require('component_meta_file','update_model')
module DTK
  class ComponentMetaFile
    extend UpdateModelClassMixin
    include UpdateModelMixin

    #TODO: move create_meta_file_object and create_from_file_obj_hash? to take moudle branch objects, rather than impleemntation (which wil get more hidden and eventually deprecated
    #source_impl is where content of file is gotten from, target_impl is where it is cloned to; if target_impl omitted then sourec and target the same
    def self.create_meta_file_object(repo,source_impl,container_idh=nil,target_impl=nil)
      unless meta_filename = meta_filename(repo)
        raise Error.new("No component meta file found")
      end
      file_obj_hash = {:path => meta_filename,:implementation => source_impl}
      content = RepoManager.get_file_content(file_obj_hash,{:implementation => source_impl})
      create_from_file_obj_hash?(target_impl,file_obj_hash,content,container_idh)
    end

    #creates a ComponentMetaFile if file_obj_hash is a r8meta file
    def self.create_from_file_obj_hash?(target_impl,file_obj_hash,content,container_idh=nil)
      filename =  file_obj_hash[:path]
      return nil unless isa_meta_filename?(filename)
      config_agent_type,file_extension = parse_meta_filename(filename)
      format_type = ExtensionToType[file_extension]
      raise Error.new("illegal file extension #{file_extension}") unless file_extension
      module_branch_idh = target_impl.get_module_branch().id_handle()
      input_hash = convert_to_hash(format_type,content)
      self.new(config_agent_type,target_impl.id_handle(),module_branch_idh,input_hash,container_idh)
    end
    ExtensionToType = {
      "yml" => :yaml
    }

    class << self
     private
      def meta_filename(repo)
        depth = 1
        RepoManager.ls_r(depth,{:file_only => true},repo).find{|f|f =~ MetaFilenameRegexp}
      end
      #returns [config_agent_type,file_extension]
      def isa_meta_filename?(filename)
        filename =~ MetaFilenameRegexp
      end
      def parse_meta_filename(filename)
        if filename =~ MetaFilenameRegexp
          [$1.to_sym,$2]
        else
          raise Error.new("Component filename (#{filename}) has illegal form")
        end
      end
      MetaFilenameRegexp = /^r8meta\.([a-z]+)\.([a-z]+$)/
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
        @cached_adapter_class[version_integer] = DynamicLoader.load_and_return_adapter_class("component_meta_file",adapter_name)
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
        #TODO: raise parsing error to user
        YAML.load(content)
      end
    end
  end
end
