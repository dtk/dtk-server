module XYZ
  module AttributeUpdateValuesClassMixin
    def update_attribute_values(attr_mh,new_val_rows,cols_x,opts={})
      #break up by type of row and process and aggregate
      return Array.new if new_val_rows.empty?
      cols = Array(cols_x)
      ndx_new_val_rows = new_val_rows.inject({}) do |h,r|
        index = Aux::demodulize(r.class.to_s)
        (h[index] ||= Array.new) << r
        h
      end
      ndx_new_val_rows.map do |type,rows|
        update_attribute_values_aux(type,attr_mh,rows,cols,opts)
      end.flatten
    end

   private
    def update_attribute_values_aux(type,attr_mh,new_val_rows,cols,opts={})
      case type
        when "OutputArrayAppend"
          update_attribute_values_array_append(attr_mh,new_val_rows,cols,opts)
        when "OutputPartial"
          update_attribute_values_partial(attr_mh,new_val_rows,cols,opts)
        else
        update_select_ds = SQL::ArrayDataset.create(db,new_val_rows,attr_mh,:convert_for_update => true)
        update_from_select(attr_mh,FieldSet.new(:attribute,cols),update_select_ds,opts)
      end
    end
    #appends value to any array type; if the array does not exist already it creates it from fresh
    def update_attribute_values_array_append(attr_mh,array_slice_rows,cols,opts={})
      #TODO: make sure cols is what expect
      #raise Error.new unless cols == [:value_derived]
      attr_link_updates = Array.new
      array_slice_rows.each do |r|
        offset = execute_function(:append_to_array_value,attr_mh,r[:id],json_generate(r[:array_slice]))
        last_el = r[:array_slice].size-1
        index_map = r[:output_is_scalar] ?
          AttributeLink::IndexMap.generate_for_output_scalar(last_el,offset) :
          AttributeLink::IndexMap.generate_from_bounds(0,last_el,offset) 
        attr_link_update = {
          :id => r[:attr_link_id],
          :index_map => index_map
        }
        attr_link_updates << attr_link_update
      end
      attr_link_mh = attr_mh.createMH(:attribute_link)
      update_from_rows(attr_link_mh,attr_link_updates)
    end

    def update_attribute_values_partial(attr_mh,partial_update_rows,cols,opts={})
      index_map_list = partial_update_rows.map{|r|r[:index_map] unless r[:index_map_persisted]}.compact
      cmp_mh = attr_mh.createMH(:component)
      AttributeLink::IndexMap.resolve_input_paths!(index_map_list,cmp_mh)
      id_list = partial_update_rows.map{|r|r[:id]}

      ndx_attr_updates = Hash.new
      select_process_and_update(attr_mh,[:id,:value_derived],id_list) do |existing_vals|
        ndx_existing_vals = existing_vals.inject({}) do |h,r|
          h.merge(r[:id] => r[:value_derived])
        end
        partial_update_rows.each do |r|
          attr_id = r[:id]
          existing_val = (ndx_attr_updates[attr_id]||{})[:value_derived] || ndx_existing_vals[attr_id]
          ndx_attr_updates[attr_id] = {
            :id => attr_id,
            :value_derived => r[:index_map].merge_into(existing_val,r[:output_value])
          }
        end
        ndx_attr_updates.values
      end
      attr_updates = ndx_attr_updates.values

      attr_link_updates = Array.new
      ndx_attr_updates = Hash.new
      attr_link_updates = partial_update_rows.map do |r|
        unless r[:index_map_persisted]
          {
            :id => r[:attr_link_id],
            :index_map => r[:index_map]
          }
        end
      end.compact
      unless attr_link_updates.empty?
        update_from_rows(attr_mh.createMH(:attribute_link),attr_link_updates)
      end

      #TODO: need to check what really changed
      attr_updates.map{|r|Aux.hash_subset(r,[:id])}
    end

    def json_generate(v)
      (v.kind_of?(Hash) or v.kind_of?(Array)) ? JSON.generate(v) : v
    end
  end
end
