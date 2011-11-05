module XYZ
  class Library < Model
#    set_relation_name(:library,:library)

    ##### Actions
    #TODO: this jsut for assemblies shoudl shoudl probably be reanmed
    def clone_post_copy_hook(clone_copy_output,opts={})
      new_id_handle = clone_copy_output.id_handles.first
      #TODO: hack; this should be optained from clone_copy_output
      new_assembly_obj = new_id_handle.create_object().update_object!(:display_name)
      case new_id_handle[:model_name]
       when :component then clear_dynamic_attributes(new_id_handle,opts)
      end
      level = 1
      node_hash_list = clone_copy_output.get_children_object_info(level,:node)
      unless node_hash_list.empty?
        node_mh = new_id_handle.createMH(:node)
        clone_post_copy_hook__child_nodes(node_mh,node_hash_list,new_assembly_obj) 
      end
    end
   private
    def clone_post_copy_hook__child_nodes(node_mh,node_hash_list,new_assembly_obj)
      rows = node_hash_list.map do |r|
        ext_ref = r[:external_ref] && r[:external_ref].reject{|k,v|k == :instance_id}.merge(:type => "ec2_image")
        update_row = {
          :id => r[:id],
          :external_ref =>  ext_ref,
          :operational_status => nil,
          :is_deployed => false
        }
        assembly_name = new_assembly_obj[:display_name]
        update_row[:display_name] = "#{assembly_name}-#{r[:display_name]}" if assembly_name and r[:display_name]
        update_row
      end
      Model.update_from_rows(node_mh,rows)
    end

    def clear_dynamic_attributes(new_id_handle,opts)
      attr_mh_to_propagate = Array.new
      #process the dynamic node attributes
      attr_mh_to_propagate += process_dynamic_attributes(:node,new_id_handle)
      #process the dynamic component attributes
      attr_mh_to_propagate += process_dynamic_attributes(:component,new_id_handle)
  
      AttributeLink.propagate(attr_mh_to_propagate) unless attr_mh_to_propagate.empty?
    end
   private
    #returns id_handles of attributes to null
    def process_dynamic_attributes(model_name,new_id_handle)
      if model_name == :component
        col = :node_assembly_parts_cmp_attrs
      elsif model_name == :node
        col = :node_assembly_parts_node_attrs
      else
        raise Error.new("unexpected model_name #{model_name}")
      end
      sp_hash = {
        :relation => :component,
        :filter => [:and,[:eq, :id, new_id_handle.get_id()],[:eq, :type, "composite"]],
        :columns => [col]
      }
      attrs = Model.get_objs(new_id_handle.createMH(model_name),sp_hash).map{|r|r[:attribute]}
      attrs_to_null = attrs.map do |attr|
        next unless attr[:dynamic]
        val = attr[:attribute_value]
        #TODO: removed old which had check if checking against both  value asseretd and value derived is right?
        #if attr[:dynamic] and not (attr[:value_asserted].nil? or attr[:value_derived] == [nil])
        nulled_val = val.kind_of?(Array) ? val.map{|x|nil} : nil
        unless val == nulled_val
          {:id => attr[:id],:value_asserted => nulled_val}
        end
      end.compact
      unless attrs_to_null.empty?
        attr_mh = new_id_handle.createMH(:model_name => :attribute,:parent_model_name => model_name)
        Model.update_from_rows(attr_mh,attrs_to_null)
        attrs_to_null.map{|attr|attr_mh.createIDH(:id => attr[:id])}
      end
      attrs_to_null.map{|attr|attr_mh.createIDH(:id => attr[:id])}
    end
  end
end
