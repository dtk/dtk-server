#TODO" unfify with generate_meta and import_export/import by moving these under component_meta_file
r8_nested_require('component_meta_file','update_model')
module DTK
  class ComponentMetaFile
    extend UpdateModelClassMixin
    include UpdateModelMixin

    def self.get_meta_file(repo,impl_idh)
      depth = 1
      meta_filename_regexp = meta_filename_regexp()
      meta_filename = RepoManager.ls_r(depth,{:file_only => true},repo).find{|f|f =~ MetaFilenameRegexp}
      unless meta_filename
        raise Error.new("No component meta file found")
      end
      file_obj_hash = {:path => meta_filename,:impl_idh => impl_idh}
      content = RepoManager.get_file_content(file_obj_hash,repo)
      create_from_file_obj_hash?(file_obj_hash,content,impl_idh)
    end

    #creates a ComponentMetaFile if file_obj_hash is a r8meta file
    def self.create_from_file_obj_hash?(file_obj_hash,content)
      filename =  file_obj_hash[:path]
      return nil unless isa_meta_filename?(filename)
      config_agent_type,file_extension = parse_meta_filename(filename)
      format_type = ExtensionToType[file_extension]
      raise Error.new("illegal file extension #{file_extension}") unless file_extension
      impl_idh = file_obj_hash[:impl_idh]||file_obj_hash[:implementation].id_handle()
      input_hash = convert_to_hash(format_type,content)
      self.new(config_agent_type,impl_idh,input_hash)
    end

    class << self
     private
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
    end
    MetaFilenameRegexp = /^r8meta\.([a-z]+)\.([a-z]+$)/
    ExtensionToType = {
      "yml" => :yaml
    }

    def initialize(config_agent_type,impl_idh,version_specific_input_hash)
      @config_agent_type = config_agent_type
      @input_hash = version_parse_check_and_normalize(version_specific_input_hash)
      @impl_idh = impl_idh
      @container_idh = impl_idh.get_parent_id_handle_with_auth_info()
      unless [:project,:library].include?(@container_idh[:model_name])
        raise Error.new("Unexpected parent type of implementation object (#{@container_idh[:model_name]})")
      end
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
      klass.normalize(version_specific_input_hash)
    end
    VersionToVersionInteger = {
      "not_specified" => 1
    }

    class << self
      def load_and_return_version_adapter_class(version_integer)
        return @cached_adapter_class if @cached_adapter_class
        adapter_name = "v#{version_integer.to_s}"
        @cached_adapter_class = DynamicLoader.load_and_return_adapter_class("component_meta_file",adapter_name)
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
