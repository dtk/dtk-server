#TODO" unfify with generate_meta and import_export/import by moving these under component_meta_file
r8_nested_require('component_meta_file','update_model')
module DTK
  class ComponentMetaFile
    extend UpdateModelClassMixin
    include UpdateModelMixin
    #creates if file_obj is a r8meta file
    def self.isa?(file_obj,content)
      return nil unless file_obj[:path] =~ /^r8meta\.([a-z]+)\.([a-z]+$)/
      config_agent_type = $1.to_sym
      file_extension = $2
      format_type = ExtensionToType[file_extension]
      raise Error.new("illegal file extension #{file_extension}") unless file_extension
      impl_idh = file_obj[:implementation].id_handle()
      input_hash = convert_to_hash(format_type,content)
      self.new(config_agent_type,impl_idh,input_hash)
    end
    ExtensionToType = {
      "yml" => :yaml
    }

    def initialize(config_agent_type,impl_idh,version_specific_input_hash)
      @config_agent_type = config_agent_type
      @input_hash = version_parse_check_and_normalize(version_specific_input_hash)
      @impl_idh = impl_idh
      @project_idh = impl_idh.get_parent_id_handle()
      unless @project_idh[:model_name] == :project
        raise Error.new("Unexpected parent type of implementation object (#{@project_idh[:model_name]})")
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
