module DTK
  class ConfigAgent
    r8_nested_require('config_agent','adapter')
    r8_nested_require('config_agent','parse_error')
    r8_nested_require('config_agent','parse_errors_cache')

    def self.parse_given_module_directory(type,dir)
      Adapter.load(type).parse_given_module_directory(dir)
    end
    def self.parse_given_filename(type,filename)
      Adapter.load(type).parse_given_filename(filename)
    end
    def self.parse_given_file_content(type,file_path,file_content)
      Adapter.load(type).parse_given_file_content(file_path,file_content)
    end

    def self.parse_external_ref?(type,impl_obj)
      processor = Adapter.load(type)
      if processor.respond_to?('parse_external_ref?'.to_sym)
        processor.parse_external_ref?(impl_obj)
      end
    end

    def node_name(node)
      (node[:external_ref]||{})[:instance_id]
    end
  end
end
