module DTK; class Attribute
  module PropagateChangesClassMixin
    # assume attribute_rows all have :value_asserted or all have :value_derived
    def update_and_propagate_attributes(attr_mh,attribute_rows,opts={})
      ret = []
      return ret if attribute_rows.empty?
      sample = attribute_rows.first
      val_field = (sample.key?(:value_asserted) ? :value_asserted : :value_derived)
      old_val_field = "old_#{val_field}".to_sym 
      
      attr_idhs = attribute_rows.map{|r|attr_mh.createIDH(id: r[:id])}
      ndx_existing_values = get_objs_in_set(attr_idhs,columns: [:id,val_field]).inject({}) do |h,r|
        h.merge(r[:id] => r)
      end

      # prune attributes change paths for attrribues taht have not changed
      ndx_ch_attr_info = {}
      attribute_rows.each do |r|
        id = r[:id]
        if ndx_existing_values[id].nil?
          ndx_ch_attr_info[id] = Aux::hash_subset(r,[:id,val_field])
          next
        end

        new_val = r[val_field]
        existing_val = ndx_existing_values[id][val_field]
        if r[:change_paths]
          r[:change_paths].each do |path|
            next if unravelled_value(new_val,path) == unravelled_value(existing_val,path)
            ndx_ch_attr_info[id] ||= Aux::hash_subset(r,[:id,val_field]).merge(:change_paths => [],old_val_field => existing_val)
            ndx_ch_attr_info[id][:change_paths] << path
          end
        elsif not (existing_val == new_val)
          ndx_ch_attr_info[id] = Aux::hash_subset(r,[:id,val_field]).merge(old_val_field => existing_val) 
        end
      end

      return ret if ndx_ch_attr_info.empty?
      changed_attrs_info = ndx_ch_attr_info.values

      update_rows = changed_attrs_info.map do |r|
        row = Aux::hash_subset(r,[:id,val_field])
        row.merge!(is_instance_value: (val_field == :value_asserted))
        row
      end

      # make actual changes in database
      opts_update = {partial_value: true}.merge(Aux.hash_subset(opts,:partial_value))
      update_from_rows(attr_mh,update_rows,opts_update)

      propagate_and_optionally_add_state_changes(attr_mh,changed_attrs_info,opts)
    end

    def update_and_propagate_dynamic_attributes(attr_mh,dyn_attr_val_info)
      attribute_rows = dyn_attr_val_info.map{|r|{:id => r[:id], dynamic_attribute_value_field() => r[:attribute_value]}}
      update_and_propagate_attributes(attr_mh,attribute_rows,add_state_changes: false)
    end

    def propagate_and_optionally_add_state_changes(attr_mh,changed_attrs_info,opts={})
      return [] if changed_attrs_info.empty?
      # default is to add state changes
      add_state_changes = ((not opts.key?(:add_state_changes)) || opts[:add_state_changes])

      change_hashes_to_propagate = create_change_hashes(attr_mh,changed_attrs_info,opts)
      direct_scs = (add_state_changes ? StateChange.create_pending_change_items(change_hashes_to_propagate) : [])
      ndx_nested_change_hashes = propagate_changes(change_hashes_to_propagate)
      indirect_scs = (add_state_changes ? StateChange.create_pending_change_items(ndx_nested_change_hashes.values) : [])
      direct_scs + indirect_scs
    end

    def propagate_changes(change_hashes)
      ret = {}
      return ret if change_hashes.empty?
      output_attr_idhs = change_hashes.map{|ch|ch[:new_item]}
      scalar_attrs = [:id,:value_asserted,:value_derived,:semantic_type]
      attr_link_rows = get_objs_in_set(output_attr_idhs,columns: scalar_attrs + [:linked_attributes])

      # dont propagate to attributes with asserted values TODO: push this restriction into search pattern
      attr_link_rows.reject!{|r|(r[:input_attribute]||{})[:value_asserted]}
      return ret if attr_link_rows.empty?

      # output_id__parent_idhs used to splice in parent_id (if it exists
      output_id__parent_idhs =  change_hashes.inject({}) do |h,ch|
        h.merge(ch[:new_item].get_id() => ch[:parent])
      end

      attrs_links_to_update = attr_link_rows.map do |r|
        output_attr = Aux::hash_subset(r,scalar_attrs)
        {
          input_attribute: r[:input_attribute],
          output_attribute: output_attr,
          attribute_link: r[:attribute_link],
          parent_idh: output_id__parent_idhs[output_attr[:id]]
        }
      end
      attr_mh = output_attr_idhs.first.createMH() #first is just a sample
      AttributeLink.propagate(attr_mh,attrs_links_to_update)
    end

    def clear_dynamic_attributes_and_their_dependents(attrs,opts={})    
      ret = []
      return ret if attrs.empty?
      attribute_rows = attrs.map do |attr|
        {
          :id => attr[:id], 
          dynamic_attribute_value_field() => dynamic_attribute_clear_value(attr)
        }
      end
      attr_mh = attrs.first.model_handle()
      update_and_propagate_attributes(attr_mh,attribute_rows,opts)
    end

    private

    def create_change_hashes(attr_mh,changed_attrs_info,opts={})
      ret = []
      # use sample attribute to find containing datacenter
      sample_attr_idh = attr_mh.createIDH(id: changed_attrs_info.first[:id])

      add_state_changes = ((not opts.key?(:add_state_changes)) || opts[:add_state_changes])
      # TODO: anymore efficieny way do do this; can pass datacenter in fn
      # TODO: when in nested call want to use passed in parent
      parent_idh = (add_state_changes ? sample_attr_idh.get_top_container_id_handle(:datacenter) : nil)
      changed_attrs_info.map do |r|
        hash = {
          new_item: attr_mh.createIDH(id: r[:id]),
          parent: parent_idh,
          change: {
            # TODO: check why before it had a json encode on values
            # think can then just remove below
            #            :old => json_form(r[old_val_index]),
            #            :new => json_form(r[val_index])
            old: r[:old_value_asserted] || r[:old_value_derived],
            new: r[:value_asserted] || r[:value_derived]
          }
        }
        hash.merge!(change_paths: r[:change_paths]) if r[:change_paths]
        hash
      end
    end

    def dynamic_attribute_value_field
      :value_derived
    end

    def dynamic_attribute_clear_value(attr)
      attr.is_a?(Array) ? attr.map{|_x|nil} : nil
    end
  end
end; end

