r8_nested_require('service_add_on','service_node_binding')
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

    def self.import(container_idh,module_name,meta_file,hash_content,ports,aug_assembly_nodes)
      Import.new(container_idh,module_name,meta_file,hash_content,ports,aug_assembly_nodes).import()
    end
    def self.dsl_filename_path_info()
      Import.dsl_filename_path_info()
    end

    def new_sub_assembly_name(base_assembly,sub_assembly_template)
      #TODO: race condition in time name generated and commited to db
      existing_sub_assemblies = base_assembly.get_sub_assemblies()
      name_prefix = "#{base_assembly[:display_name]}::#{sub_assembly_template[:display_name]}"
      matching_instance_nums = Array.new
      existing_sub_assemblies.each do |a|
        if a[:display_name] =~ Regexp.new("^#{name_prefix}(.*$)")
          suffix = $1
          suffix_num  = (suffix.empty? ? 1 : (suffix =~ /^-([0-9]+$)/; $1))
          matching_instance_nums << suffix_num.to_i
        end
      end
      if matching_instance_nums.empty?
        name_prefix
      else
        "#{name_prefix}-#{(matching_instance_nums.max+1).to_s}"
      end
    end
  end
end
