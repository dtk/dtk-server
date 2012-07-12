#TODO" unify with generate_meta
r8_nested_require('component_meta_file','update_model')
module DTK
  class ComponentMetaFile
    include ComponentMetaFileUpdateModelMixin
    #creates if file_obj is a r8meta file
    def self.isa?(file_obj,content)
      return nil unless file_obj[:path] =~ /^r8meta\.([a-z]+)\.([a-z]+$)/
      config_agent_type = $1.to_sym
      file_extension = $2
      format_type = ExtensionToType[file_extension]
      raise Error.new("illegal file extension #{file_extension}") unless file_extension
      impl_idh = file_obj[:implementation].id_handle()
      hash_content = convert_to_hash(format_type,content)
      self.new(config_agent_type,impl_idh,hash_content)
    end
    ExtensionToType = {
      "yml" => :yaml
    }

    def initialize(config_agent_type,impl_idh,version_specific_hash_content)
      @config_agent_type = config_agent_type
      @hash_content = version_normalize(version_specific_hash_content)
      @impl_idh = impl_idh
    end
   private
    def version_normalize(version_specific_hash_content)
      version = version_specific_hash_content["version"]||"not_specified"
      unless version_integer = VersionToVersionInteger[version]
        raise ErrorUsage.new("Illegal version (#{version}) found in meta file")
      end
      klass = self.class.load_and_return_version_adapter_class(version_integer)
      klass.normalize(version_specific_hash_content)
    end
    VersionToVersionInteger = {
      "not_specified" => 1
    }

    def self.load_and_return_version_adapter_class(version_integer)
      return @cached_adapter_class if @cached_adapter_class
      adapter_name = "v#{version_integer.to_s}"
      @cached_adapter_class = DynamicLoader.load_and_return_adapter_class("component_meta_file",adapter_name)
    end

    def self.convert_to_hash(format_type,content)
      case format_type
      when :yaml then convert_to_hash_yaml(content)
      else
        raise Error.new("cannot treat format type #{format_type}")
      end
    end
    def self.convert_to_hash_yaml(content)
      #TODO: raise parsing error to user
      YAML.load(content)
    end
  end
end
