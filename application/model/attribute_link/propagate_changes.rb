module XYZ
  module AttrLinkPropagateChangesClassMixin
    def propagate(output_attr_idhs,parent_id_handles=nil)
      ret = Hash.new
      return ret if output_attr_idhs.empty?
      scalar_attrs = [:id,:value_asserted,:value_derived,:semantic_type]

      attr_link_rows = get_objs_in_set(output_attr_idhs,:columns => scalar_attrs + [:linked_attributes])

      #dont propagate to attributes with asserted values TODO: push this restriction into search pattern
      attr_link_rows.reject!{|r|(r[:input_attribute]||{})[:value_asserted]}
      return ret if attr_link_rows.empty?

      #output_id__parent_idhs used to splice in parent_id (if it exists
      output_id__parent_idhs = Hash.new
      if parent_id_handles
        output_attr_idhs.each_with_index{|idh,i|output_id__parent_idhs[idh.get_id()] = parent_id_handles[i]}
      end
      attrs_links_to_update = attr_link_rows.map do |r|
        output_attr = Aux::hash_subset(r,scalar_attrs)
        {
          :input_attribute => r[:input_attribute],
          :output_attribute => output_attr,
          :attribute_link => r[:attribute_link],
          :parent_idh => output_id__parent_idhs[output_attr[:id]]
        }
      end
      attr_mh = output_attr_idhs.first.createMH() #first is just a sample
      new_propagate(attr_mh,attrs_links_to_update)
    end
    private

    #hash top level with :input_attribute,:output_attribute,:attribute_link, :parent_idh (optional)
    #with **_attribute having :id,:value_asserted,:value_derived,:semantic_type
    #  :attribute_link having :function, :input_id, :output_id, :index_map
    def new_propagate(attr_mh,attrs_links_to_update)
      ret = Hash.new
      #compute update deltas
      update_deltas = compute_update_deltas(attrs_links_to_update)

      #make actual changes
      opts = {:update_only_if_change => [:value_derived],:returning_cols => [:id]}
      
      changed_input_attrs = AttributeUpdateDerivedValues.update(attr_mh,update_deltas,opts)

      #if no changes exit, otherwise recursively call propagate
      return ret if changed_input_attrs.empty?

      #input attr parents are set to associated output attrs parent
      output_id__parent_idhs = attrs_links_to_update.inject({}) do |h,r|
        h.merge(r[:output_attribute][:id] => r[:parent_idh])
      end

      #compute direct changes and input for nested propagation
      direct_changes = Hash.new
      nested_parent_idhs = nil
      nested_idhs = changed_input_attrs.map do |r|
        id = r[:id]
        change = {
          :new_item => attr_mh.createIDH(:id => r[:id]),
          :change => {:old => r[:old_value_derived], :new => r[:value_derived]}
        }
        if parent_idh = output_id__parent_idhs[r[:source_output_id]]
          change.merge!(:parent => parent_idh)
          #assumption if this fires for one element it fires from them all (if one has a parent, they all do)
          (nested_parent_idhs ||= Array.new) << parent_idh
        end
        direct_changes[id] = change 
        attr_mh.createIDH(:id => id)
      end
      
      #nested (recursive) propagatation call
      propagated_changes = propagate(nested_idhs,nested_parent_idhs)
      #return all changes
      #TODO: using flat structure wrt to parents; so if parents pushed down use parents associated with trigger for change
      direct_changes.merge(propagated_changes)
    end
   private
    def compute_update_deltas(attrs_links_to_update)
      attrs_links_to_update.map do |r|
        input_attr = r[:input_attribute]
        output_attr = r[:output_attribute]
        propagate_proc = PropagateProcessor.new(r[:attribute_link],input_attr,output_attr)
        propagate_proc.propagate().merge(:id => input_attr[:id], :source_output_id => output_attr[:id])
      end
    end


=begin
    #returns all changes
    #TODO: flat list now; look at nested list reflecting hierarchical plan decomposition
    #TODO: rather than needing look up existing values for output vars; might allow change/new values to be provided as function arguments
    #TODO: may clean up to avoid needing two eqal length arrays: output_attr_id_handles,parent_id_handles (when later is not nil)
    def propagate(output_attr_id_handles,parent_id_handles=nil)
      ret = Hash.new
      return ret if output_attr_id_handles.empty?
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
      return ret if attrs_to_update.empty?

      #compute update deltas
      update_deltas = compute_update_deltas(attrs_to_update)

      #make actual changes
      opts = {:update_only_if_change => [:value_derived],:returning_cols => [:id]}
      changed_input_attrs = AttributeUpdateDerivedValues.update(attr_mh,update_deltas,opts)

      #if no changes exit, otherwise recursively call propagate
      return ret if changed_input_attrs.empty?

      #input attr parents are set to associated output attrs parent
      output_id__parent_idhs = Hash.new
      if parent_id_handles
        output_attr_ids.each_with_index{|id,i|output_id__parent_idhs[id] = parent_id_handles[i]}
      end

      #compute direct changes and input for nested propagation
      direct_changes = Hash.new
      nested_parent_idhs = nil
      nested_idhs = changed_input_attrs.map do |r|
        id = r[:id]
        change = {
          :new_item => attr_mh.createIDH(:id => r[:id]),
          :change => {:old => r[:old_value_derived], :new => r[:value_derived]}
        }
        if parent_idh = output_id__parent_idhs[r[:source_output_id]]
          change.merge!(:parent => parent_idh)
          #assumption if this fires for one element it fires from them all (if one has a parent, they all do)
          (nested_parent_idhs ||= Array.new) << parent_idh
        end
        direct_changes[id] = change 
        attr_mh.createIDH(:id => id)
      end
      
      #nested (recursive) propagatation call
      propagated_changes = propagate(nested_idhs,nested_parent_idhs)
      #return all changes
      #TODO: using flat structure wrt to parents; so if parents pushed down use parents associated with trigger for change
      direct_changes.merge(propagated_changes)
    end
=end
    def propagate_from_create(attr_mh,attr_info,attr_link_rows)
      new_val_rows = attr_link_rows.map do |attr_link_row|
        input_attr = attr_info[attr_link_row[:input_id]]
        output_attr = attr_info[attr_link_row[:output_id]]
        propagate_proc = PropagateProcessor.new(attr_link_row,input_attr,output_attr)
        propagate_proc.propagate().merge(:id => input_attr[:id])
      end
      return Array.new if new_val_rows.empty?
      AttributeUpdateDerivedValues.update(attr_mh,new_val_rows)
    end
  end
end
