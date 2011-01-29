
module XYZ
  class Library < Model
    set_relation_name(:library,:library)
    def self.up()
      #no table specfic fields (yet)
      one_to_many :component, :node, :component_def, :node_group, :node_group_member, :attribute_link, :network_partition, :network_gateway, :region,:assoc_region_network, :data_source, :search_object
    end
    ##### Actions
    def self.clone_post_copy_hook(new_id_handle,target_id_handle,opts={})
      case new_id_handle[:model_name]
       when :component then clone_post_copy_hook__component(new_id_handle,target_id_handle,opts)
      end
    end
   private
    def self.clone_post_copy_hook__component(new_id_handle,target_id_handle,opts)
      #find if assembly and if so get what it is directly linked to
      search_pattern_hash = {
        :relation => :component,
        :filter => [:and,[:eq, :id, new_id_handle.get_id()],[:eq, :type, "composite"]],
        :columns => [:node_assembly_parts]
      }
      node_assembly_parts = Model.get_objects_from_search_pattern_hash(new_id_handle.createMH(:model_name => :component),search_pattern_hash)
      pp [:node_assembly_parts,node_assembly_parts]
    end
  end
end
