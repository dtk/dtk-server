module XYZ
  class Library < Model
#    set_relation_name(:library,:library)

    ##### Actions
    def clone_post_copy_hook(clone_copy_output,opts={})
      new_id_handle = clone_copy_output.id_handles.first
      case new_id_handle[:model_name]
       when :component then clear_dynamic_attributes(new_id_handle,opts)
      end
      level = 1
      node_hash_list = clone_copy_output.get_children_object_info(level,:node)
      unless node_hash_list.empty?
        node_mh = new_id_handle.createMH(:node)
        clone_post_copy_hook__child_nodes(node_mh,node_hash_list) 
      end
    end
   private
    def clone_post_copy_hook__child_nodes(node_mh,node_hash_list)
      rows = node_hash_list.map do |r|
        ext_ref = r[:external_ref] && r[:external_ref].reject{|k,v|k == :instance_id}.merge(:type => "ec2_image")
        {:id => r[:id],:external_ref =>  ext_ref}
      end
      Model.update_from_rows(node_mh,rows)
    end

    def clear_dynamic_attributes(new_id_handle,opts)
      attr_mh_to_propagate = Array.new
      #process the dynamic node attributes
      sp_hash = {
        :relation => :component,
        :filter => [:and,[:eq, :id, new_id_handle.get_id()],[:eq, :type, "composite"]],
        :columns => [:node_assembly_parts_node_attrs]
      }
      node_attrs = Model.get_objs(new_id_handle.createMH(:component),sp_hash).map{|r|r[:attribute]}
      attrs_to_null = node_attrs.map do |attr|
        if attr[:dynamic] and not (attr[:value_asserted].nil? or attr[:value_derived] == [nil])
          {:id => attr[:id],:value_asserted => [nil]}
        end
      end.compact
      unless attrs_to_null.empty?
        attr_mh = new_id_handle.createMH(:model_name => :attribute,:parent_model_name => :node)
        Model.update_from_rows(attr_mh,attrs_to_null)
        attr_mh_to_propagate += attrs_to_null.map{|attr|attr_mh.createIDH(:id => attr[:id])}
      end

      #process the dynamic component attributes
      sp_hash = {
        :relation => :component,
        :filter => [:and,[:eq, :id, new_id_handle.get_id()],[:eq, :type, "composite"]],
        :columns => [:node_assembly_parts_cmp_attrs]
      }
      cmp_attrs = Model.get_objs(new_id_handle.createMH(:component),sp_hash).map{|r|r[:attribute]}
      attrs_to_null = cmp_attrs.map do |attr|
        if attr[:dynamic] and not (attr[:value_asserted].nil? or attr[:value_derived] == [nil])
          {:id => attr[:id],:value_asserted => [nil]}
        end
      end.compact
      unless attrs_to_null.empty?
        attr_mh = new_id_handle.createMH(:model_name => :attribute,:parent_model_name => :component)
        Model.update_from_rows(attr_mh,attrs_to_null)
        attr_mh_to_propagate += attrs_to_null.map{|attr|attr_mh.createIDH(:id => attr[:id])}
      end
  
      #TODO: switch over to AttributeLink.propagate
      AttributeLink.propagate(attr_mh_to_propagate) unless attr_mh_to_propagate.empty?
    end
  end
end
