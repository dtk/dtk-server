module XYZ
  module AttrLinkPropagateChangesClassMixn
    #returns all changes
    #TODO: flat list now; look at nested list reflecting hierarchical plan decomposition
    #TODO: rather than needing look up existing values for output vars; might allow change/new values to be provided as function arguments
    def propagate(output_attr_id_handles,parent_id_handles=nil)
      return Hash.new if output_attr_id_handles.empty?
      attr_mh = output_attr_id_handles.first.createMH()
      output_attr_ids = output_attr_id_handles.map{|idh|idh.get_id()}
      sp_hash = {
        :relation => :attribute,
        :filter => [:and,[:oneof, :id, output_attr_ids]],
        :columns => [:id,:value_asserted,:value_derived,:semantic_type,:linked_attributes]
      }
      attrs_to_update = get_objs(attr_mh,sp_hash)
    
      #dont propagate to attributes with asserted values TODO: push this restriction into search pattern
      attrs_to_update.reject!{|r|(r[:input_attribute]||{})[:value_asserted]}
      change_info = Hash.new
      new_val_rows = Array.new
      
      parent_map = Hash.new
      if parent_id_handles
        output_attr_ids.each_with_index{|id,i|parent_map[id] = parent_id_handles[i]}
      end

      attrs_to_update.each_with_index do |row,i|
        input_attr_row = row[:input_attribute]
        output_attr_row = row
        propagate_proc = PropagateProcessor.new(row[:attribute_link],input_attr_row,output_attr_row)

        new_value_row = propagate_proc.propagate().merge(:id => input_attr_row[:id])

        new_val_rows << new_value_row

        change = {
          :new_item => attr_mh.createIDH(:guid => input_attr_row[:id], :display_name => input_attr_row[:display_name]),
          :change => {:old => input_attr_row[:value_derived], :new => new_value_row[:value_derived]}
        }
        change.merge!(:parent => parent_map[row[:id]]) if parent_map[row[:id]]
        change_info[input_attr_row[:id]] = change
      end

      return Hash.new if new_val_rows.empty?
      opts = {:update_only_if_change => [:value_derived],:returning_cols => [:id]}
      changed_ids = AttributeUpdateDerivedValues.update(attr_mh,new_val_rows,:value_derived,opts)
      #if no changes exit, otherwise recursively call propagate
      return Hash.new if changed_ids.empty?

      #TODO: using flat structure wrt to parents; so if parents pushed down use parents associated with trigger for change
      pruned_changes = Hash.new
      nested_parent_idhs = nil
      nested_idhs = Array.new
      changed_ids.each do |r|
        id = r[:id]
        pruned_changes[id] = change_info[id]
        nested_idhs << attr_mh.createIDH(:id => id)
        if parent_idh = change_info[id][:parent]
          nested_parent_idhs ||= Array.new
          nested_parent_idhs << parent_idh
        end
      end
      
      propagated_changes = propagate(nested_idhs,nested_parent_idhs)
      pruned_changes.merge(propagated_changes)
    end

    def propagate_from_create(attr_mh,attr_info,attr_link_rows)
      new_val_rows = attr_link_rows.map do |attr_link_row|
        input_attr = attr_info[attr_link_row[:input_id]]
        output_attr = attr_info[attr_link_row[:output_id]]
        propagate_proc = PropagateProcessor.new(attr_link_row,input_attr,output_attr)
        propagate_proc.propagate().merge(:id => input_attr[:id])
      end
      return Array.new if new_val_rows.empty?
      AttributeUpdateDerivedValues.update(attr_mh,new_val_rows,[:value_derived])
    end
  end
end
