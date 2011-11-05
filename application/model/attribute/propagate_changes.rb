module XYZ
  module AttrPropagateChangesClassMixin
    #TODO: may want to rename to indicate this is propgate while logging state changes; or have a flag to control whether state changes are logged
    def update_and_propagate_attributes(attr_mh,attribute_rows)
      ret = Array.new
      return ret if attribute_rows.empty?
      attr_idhs = attribute_rows.map{|r|attr_mh.createIDH(:id => r[:id])}
      ndx_existing_values = get_objs_in_set(attr_idhs,:columns => [:id,:value_asserted]).inject({}) do |h,r|
        h.merge(r[:id] => r)
      end

      #prune attributes change paths for attrribues taht have not changed
      ndx_ch_attr_info = Hash.new
      attribute_rows.each do |r|
        id = r[:id]
        if ndx_existing_values[id].nil?
          ndx_ch_attr_info[id] = Aux::hash_subset(r,[:id,:value_asserted])
          next
        end

        new_val = r[:value_asserted]
        existing_val = ndx_existing_values[id][:value_asserted]
        if r[:change_paths]
          r[:change_paths].each do |path|
            next if unravelled_value(new_val,path) == unravelled_value(existing_val,path)
            ndx_ch_attr_info[id] ||= Aux::hash_subset(r,[:id,:value_asserted]).merge(:change_paths => Array.new,:old_value_asserted => existing_val)
            ndx_ch_attr_info[id][:change_paths] << path
          end
        elsif not (existing_val == new_val)
          ndx_ch_attr_info[id] = Aux::hash_subset(r,[:id,:value_asserted]).merge(:old_value_asserted => existing_val) 
        end
      end

      return ret if ndx_ch_attr_info.empty?
      changed_attrs_info = ndx_ch_attr_info.values

      update_rows = changed_attrs_info.map{|r|Aux::hash_subset(r,[:id,:value_asserted])}

      #make acual changes in database
      update_from_rows(attr_mh,update_rows,:partial_value => true)

      add_attr_state_changes_and_propagate(attr_mh,changed_attrs_info)
    end

    def add_attr_state_changes_and_propagate(attr_mh,changed_attrs_info)
      return Array.new if changed_attrs_info.empty?
      change_hashes_to_propagate = create_change_hashes(attr_mh,changed_attrs_info)
      direct_scs = StateChange.create_pending_change_items(change_hashes_to_propagate)
      ndx_nested_change_hashes = propagate_changes(change_hashes_to_propagate)
      #TODO: need to figure ebst place to put persistence statement for state changes; complication where later state changes reference earlier ones; otherwise we can just do peristsnec at the end for whole list
      direct_scs + StateChange.create_pending_change_items(ndx_nested_change_hashes.values)
    end

    def propagate_changes(change_hashes) 
      ret = Hash.new
      return ret if change_hashes.empty?
      output_attr_idhs = change_hashes.map{|ch|ch[:new_item]}
      scalar_attrs = [:id,:value_asserted,:value_derived,:semantic_type]
      attr_link_rows = get_objs_in_set(output_attr_idhs,:columns => scalar_attrs + [:linked_attributes])

      #dont propagate to attributes with asserted values TODO: push this restriction into search pattern
      attr_link_rows.reject!{|r|(r[:input_attribute]||{})[:value_asserted]}
      return ret if attr_link_rows.empty?

      #output_id__parent_idhs used to splice in parent_id (if it exists
      output_id__parent_idhs =  change_hashes.inject({}) do |h,ch|
        h.merge(ch[:new_item].get_id() => ch[:parent])
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
      AttributeLink.propagate(attr_mh,attrs_links_to_update)
    end

    def create_change_hashes(attr_mh,changed_attrs_info)
      ret = Array.new
      #use sample attribute to find containing datacenter
      sample_attr_idh = attr_mh.createIDH(:id => changed_attrs_info.first[:id])
      #TODO: anymore efficieny way do do this; can pass datacenter in fn
      #TODO: when in nested call want to use passed in parent
      parent_idh = sample_attr_idh.get_top_container_id_handle(:datacenter)
      changed_attrs_info.map do |r|
        hash = {
          :new_item => attr_mh.createIDH(:id => r[:id]),
          :parent => parent_idh,
          :change => {
            #TODO: check why before it had a json encode on values
            #think can then just remove below
#            :old => json_form(r[old_val_index]),
#            :new => json_form(r[val_index])
            :old => r[:old_value_asserted] || r[:old_value_derived],
            :new => r[:value_asserted] || r[:value_derived]
          }
        }
        hash.merge!(:change_paths => r[:change_paths]) if r[:change_paths]
        hash
      end
    end


    def clear_dynamic_attributes_and_their_dependents(attr_idhs)    
      ret = Array.new
      return ret if attr_idhs.empty?
      clear_val = dynamic_attribute_clear_value()
      attribute_rows = attr_idhs.map{|attr_idh|{:id => attr_idh.get_id(), :value_asserted => clear_val}}
      attr_mh = attr_idhs.first.createMH()
      update_and_propagate_attributes(attr_mh,attribute_rows)
    end
    private

    def dynamic_attribute_clear_value()
      nil
    end
  end
end
