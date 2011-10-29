module XYZ
  class AttributeUpdateDerivedValues
    def self.update(attr_mh,new_val_rows,opts={})
      attr_ids = new_val_rows.map{|r|r[:id]}
      critical_section(attr_ids) do
        update_in_critical_section(attr_mh,new_val_rows,opts={})
      end
    end

    def self.update_for_delete_links(attr_mh,links_info)
      attr_ids = links_info.map{|l|l[:attribute_id]}
      critical_section(attr_ids) do
        links_info.each{|link_info|update_attr_for_delete_link(attr_mh,link_info)}
      end
    end

   private
    Lock = Mutex.new
    def self.critical_section(attr_ids,&block)
      #passing in attr_ids, but not using now; may use if better to lock on per attribute basis
      Lock.synchronize{yield}
    end

    def self.update_in_critical_section(attr_mh,new_val_rows,opts={})
      #break up by type of row and process and aggregate
      return Array.new if new_val_rows.empty?
      ndx_new_val_rows = new_val_rows.inject({}) do |h,r|
        index = Aux::demodulize(r.class.to_s)
        (h[index] ||= Array.new) << r
        h
      end
      ndx_new_val_rows.map do |type,rows|
        update_attribute_values_aux(type,attr_mh,rows,opts)
      end.flatten
    end

    def self.update_attr_for_delete_link(attr_mh,link_info)
      #if (input) attribute is array then need to splice out; otherwise just need to set to null
      input_index = input_index(link_info[:deleted_link])
      if input_index.nil? or input_index.empty?
        update_attr_for_delete_link__set_to_null(attr_mh,link_info)
      else
        update_attr_for_delete_link__splice_out(attr_mh,link_info,input_index)
      end
    end

    def self.input_index(link_hash)
      input_output_index_aux(link_hash,:input)
    end
    def self.output_index(link_hash)
      input_output_index_aux(link_hash,:output)
    end
    def self.input_output_index_aux(link_hash,dir)
      index_map = link_hash[:index_map]
      unless index_map.size == 1
        raise Error.new("not treating update_for_delete_link when index_map size is unequal to 1")
      end   
      index_map.first && index_map.first[dir]
    end

    def self.update_attr_for_delete_link__set_to_null(attr_mh,link_info)
      row_to_update = {
        :id =>link_info[:attribute_id],
        :value_derived => nil
      }
      Model.update_from_rows(attr_mh,[row_to_update])
    end

    def self.update_attr_for_delete_link__splice_out(attr_mh,link_info,input_index)
      #if this is last link in output then null out
      if link_info[:other_links].empty?
        update_attr_for_delete_link__set_to_null(attr_mh,link_info)
        return
      end

      #splice out the value from teh deleted link
      pos_to_delete = input_index.first 
      Model.select_process_and_update(attr_mh,[:id,:value_derived],[link_info[:attribute_id]]) do |rows|
        #will only be one row; putting in 'each' just for coding succinctness
        rows.each{|r|r[:value_derived].delete_at(pos_to_delete)}
        rows
      end
      #renumber other links (ones not deleted) if necessary
      links_to_renumber = link_info[:other_links].select do |other_link| 
        input_index(other_link).first > pos_to_delete
      end
      return if links_to_renumber.empty?
      renumber_links(attr_mh,links_to_renumber)
    end

    def self.renumber_links(attr_mh,links_to_renumber)
      rows_to_update = links_to_renumber.map do |l|
        new_input_index = input_index(l).dup
        new_input_index[0] -= 1
        new_index_map = [{:output => output_index(l), :input => new_input_index}]
        {:id => l[:attribute_link_id], :index_map => new_index_map}
      end
      Model.update_from_rows(attr_mh.createMH(:attribute_link),rows_to_update)
    end


    def self.update_attribute_values_aux(type,attr_mh,new_val_rows,opts={})
      case type
        when "OutputArrayAppend"
          update_attribute_values_array_append(attr_mh,new_val_rows,opts)
        when "OutputPartial"
          update_attribute_values_partial(attr_mh,new_val_rows,opts)
        else #TODO: below is for legacy form befor had Output objects; may convert to Output form
        update_select_ds = SQL::ArrayDataset.create(db,new_val_rows,attr_mh,:convert_for_update => true)
        Model.update_from_select(attr_mh,FieldSet.new(:attribute,[:value_derived]),update_select_ds,opts)
      end
    end
    #appends value to any array type; if the array does not exist already it creates it from fresh
    def self.update_attribute_values_array_append(attr_mh,array_slice_rows,opts={})
      attr_link_updates = Array.new
      id_list = array_slice_rows.map{|r|r[:id]}
      Model.select_process_and_update(attr_mh,[:id,:value_derived],id_list) do |existing_vals|
        ndx_existing_vals = existing_vals.inject({}) do |h,r|
          h.merge(r[:id] => r[:value_derived])
        end
        attr_updates = array_slice_rows.map do |r|
          attr_id = r[:id]
          existing_val = ndx_existing_vals[attr_id]||[]
          offset = existing_val.size
          last_el = r[:array_slice].size-1
          index_map = r[:output_is_array] ?
          AttributeLink::IndexMap.generate_from_bounds(0,last_el,offset) :
            AttributeLink::IndexMap.generate_for_output_scalar(last_el,offset) 
          attr_link_update = {
            :id => r[:attr_link_id],
            :index_map => index_map
          }
          attr_link_updates << attr_link_update
          
          #a row in new array
          {:id => attr_id, :value_derived => existing_val + r[:array_slice]}
        end
        attr_updates
      end

      #update the index_maps on the links
      Model.update_from_rows(attr_mh.createMH(:attribute_link),attr_link_updates)
    end

    def self.update_attribute_values_partial(attr_mh,partial_update_rows,opts={})
      index_map_list = partial_update_rows.map{|r|r[:index_map] unless r[:index_map_persisted]}.compact
      cmp_mh = attr_mh.createMH(:component)
      AttributeLink::IndexMap.resolve_input_paths!(index_map_list,cmp_mh)
      id_list = partial_update_rows.map{|r|r[:id]}

      ndx_attr_updates = Hash.new
      Model.select_process_and_update(attr_mh,[:id,:value_derived],id_list) do |existing_vals|
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
        Model.update_from_rows(attr_mh.createMH(:attribute_link),attr_link_updates)
      end

      #TODO: need to check what really changed
      attr_updates.map{|r|Aux.hash_subset(r,[:id])}
    end
  end
end
