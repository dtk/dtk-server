module DTK
  class ConfigAgent
    r8_nested_require('config_agent','adapter')
    r8_nested_require('config_agent','parse_error')
    r8_nested_require('config_agent','parse_errors_cache')

    def self.parse_given_module_directory(type,dir)
      load(type).parse_given_module_directory(dir)
    end
    def self.parse_given_filename(type,filename)
      load(type).parse_given_filename(filename)
    end
    def self.parse_given_file_content(type,file_path,file_content)
      load(type).parse_given_file_content(file_path,file_content)
    end

    def self.treated_version?(type,semantic_version)
      load(type).treated_version?(semantic_version)
    end

    def self.parse_external_ref?(type,impl_obj)
      processor = load(type)
      if processor.respond_to?('parse_external_ref?'.to_sym)
        processor.parse_external_ref?(impl_obj)
      end
    end

    def self.load(type)
      Adapter.load(type)
    end

    def node_name(node)
      (node[:external_ref]||{})[:instance_id]
    end

  end
end
