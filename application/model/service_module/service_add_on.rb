module DTK
  class ServiceAddOn < Model
    r8_nested_require('service_add_on','import')

    def self.import(library_idh,module_name,meta_file,hash_content,ports,aug_assembly_nodes)
      Import.new(library_idh,module_name,meta_file,hash_content,ports,aug_assembly_nodes).import()
    end

    def self.meta_filename_path_info()
      Import.meta_filename_path_info()
    end
  end
end
