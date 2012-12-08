module DTK
  class ServiceAddOn < Model
    r8_nested_require('service_add_on','import')
    ###standard get methods
    def get_service_node_bindings()
      sp_hash = {
        :cols => [:id,:group_id,:display_name,:assembly_node_id,:sub_assembly_node_id],
        :filter => [:eq,:add_on_id,id()]
      }
      Model.get_objs(model_handle(:service_node_binding),sp_hash)
    end

    def get_port_links()
      sp_hash = {
        :cols => [:id,:group_id,:display_name,:input_id,:output_id,:output_is_local,:required],
        :filter => [:eq,:service_add_on_id,id()]
      }
      Model.get_objs(model_handle(:port_link),sp_hash)
    end

    ###end standard get methods

    def self.import(library_idh,module_name,meta_file,hash_content,ports,aug_assembly_nodes)
      Import.new(library_idh,module_name,meta_file,hash_content,ports,aug_assembly_nodes).import()
    end
    def self.dsl_filename_path_info()
      Import.dsl_filename_path_info()
    end


  end
end
