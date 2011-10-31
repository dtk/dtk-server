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
      #TODO: when have comprehensive incremental change use Attribute.update_changed_values (and generalzie to take asserted as well as derived attributes)
      update_rows = changed_attrs_info.map{|r|Aux::hash_subset(r,[:id,:value_asserted])}

      #make acual cahnges in database
      update_from_rows(attr_mh,update_rows,:partial_value => true)

      #use sample attribute to find containing datacenter
      sample_attr_idh = attr_mh.createIDH(:id => changed_attrs_info.first[:id])
      #TODO: anymore efficieny way do do this; can pass datacenter in fn
      parent_idh = sample_attr_idh.get_top_container_id_handle(:datacenter)

      changes = changed_attrs_info.map do |r|
        hash = {
          :new_item => attr_mh.createIDH(:id => r[:id]),
          :parent => parent_idh,
          :change => {
            :old => json_form(r[:old_value_asserted]),
            :new => json_form(r[:value_asserted])
          }
        }
        hash.merge!(:change_paths => r[:change_paths]) if r[:change_paths]
        hash
      end
      change_idhs = StateChange.create_pending_change_items(changes)
      changes_to_propagate = Array.new
      change_idhs.each_with_index do |change_idh,i|
        change = changes[i]
        changes_to_propagate << AttributeChange.new(change[:new_item],change[:change][:new],change_idh)
      end
      nested_changes = propagate_changes(changes_to_propagate)
      StateChange.create_pending_change_items(nested_changes.values)
    end
   private
    def propagate_changes(attr_changes) 
      AttributeLink.propagate(attr_changes.map{|x|x.id_handle},attr_changes.map{|x|x.state_change_id_handle})
    end
  end
end
