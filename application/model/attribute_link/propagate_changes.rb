module DTK; class AttributeLink
  module PropagateChangesClassMixin
    # hash top level with :input_attribute,:output_attribute,:attribute_link, :parent_idh (optional)
    # with **_attribute having :id,:value_asserted,:value_derived,:semantic_type
    #  :attribute_link having :function, :input_id, :output_id, :index_map
    def propagate(attr_mh,attrs_links_to_update)
      ret = Hash.new
      # compute update deltas
      update_deltas = compute_update_deltas(attrs_links_to_update)

      # make actual changes
      opts = {:update_only_if_change => [:value_derived],:returning_cols => [:id]}
      
      changed_input_attrs = AttributeUpdateDerivedValues.update(attr_mh,update_deltas,opts)

      # if no changes exit, otherwise recursively call propagate
      return ret if changed_input_attrs.empty?

      # input attr parents are set to associated output attrs parent
      output_id__parent_idhs = attrs_links_to_update.inject({}) do |h,r|
        h.merge(r[:output_attribute][:id] => r[:parent_idh])
      end

      # compute direct changes and input for nested propagation
      # TODO: may unifty with Attribute.create_change_hashes
      ndx_direct_change_hashes = changed_input_attrs.inject({}) do |h,r|
        id = r[:id]
        change = {
          :new_item => attr_mh.createIDH(:id => id),
          :change => {:old => r[:old_value_derived], :new => r[:value_derived]}
        }
        if parent_idh = output_id__parent_idhs[r[:source_output_id]]
          change.merge!(:parent => parent_idh)
        end
        h.merge(id => change)
      end
      
      # nested (recursive) propagatation call
      ndx_propagated_changes = Attribute.propagate_changes(ndx_direct_change_hashes.values)
      # return all changes
      ndx_direct_change_hashes.merge(ndx_propagated_changes)
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
  end
end; end
