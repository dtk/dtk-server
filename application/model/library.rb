module XYZ
  class Library < Model
#    set_relation_name(:library,:library)

    ##### Actions
    def self.clone_post_copy_hook(clone_copy_output,target_id_handle,opts={})
      new_id_handle = clone_copy_output.id_handles.first
      case new_id_handle[:model_name]
       when :component then clone_post_copy_hook__component(new_id_handle,target_id_handle,opts)
      end
    end
   private
    def self.clone_post_copy_hook__component(new_id_handle,target_id_handle,opts)
      #TODO: may generalize and look for any dynamic attribute that neds to be reset when put in library
      #find if assembly and if so get what it is directly linked to
      sp_hash = {
        :relation => :component,
        :filter => [:and,[:eq, :id, new_id_handle.get_id()],[:eq, :type, "composite"]],
        :columns => [:node_assembly_parts_with_attrs]
      }
      node_assembly_parts = Model.get_objects_from_sp_hash(new_id_handle.createMH(:model_name => :component),sp_hash)
      #TODO: probably move so can be used also when clone nodes dircetly into library
      attrs_to_null = Array.new
      node_assembly_parts.each do |r|
        next unless attr = r[:attribute]
        if attr[:display_name] == "host_addresses_ipv4" and not (attr[:value_asserted].nil? or attr[:value_derived] == [nil])
          attrs_to_null << {:id => attr[:id],:value_asserted => [nil]}
        end
      end
      attr_mh = new_id_handle.createMH(:model_name => :attribute,:parent_model_name => :node)
      Model.update_from_rows(attr_mh,attrs_to_null)
      AttributeLink.propagate(attrs_to_null.map{|attr|attr_mh.createIDH(:id => attr[:id])})
    end
  end
end
