module XYZ
  class AttributeUpdateDerivedValues
    def self.update(attr_mh,update_deltas,opts={})
      ret = Array.new
      attr_ids = update_deltas.map{|r|r[:id]}
      critical_section(attr_ids) do
        ret = update_in_critical_section(attr_mh,update_deltas,opts={})
      end
      ret
    end

    def self.update_for_delete_links(attr_mh,links_info)
      ret = Array.new
      attr_ids = links_info.map{|l|l[:attribute_id]}
      critical_section(attr_ids) do
        ret = links_info.each{|link_info|update_attr_for_delete_link(attr_mh,link_info)}
      end
      ret
    end

   private
    Lock = Mutex.new
    def self.critical_section(attr_ids,&block)
      #passing in attr_ids, but not using now; may use if better to lock on per attribute basis
      Lock.synchronize{yield}
    end

    def self.update_in_critical_section(attr_mh,update_deltas,opts={})
      #break up by type of row and process and aggregate
      return Array.new if update_deltas.empty?
      ndx_update_deltas = update_deltas.inject({}) do |h,r|
        index = Aux::demodulize(r.class.to_s)
        (h[index] ||= Array.new) << r
        h
      end
      ndx_update_deltas.map do |type,rows|
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


    def self.update_attribute_values_aux(type,attr_mh,update_deltas,opts={})
      case type
        when "OutputArrayAppend"
          update_attribute_values_array_append(attr_mh,update_deltas,opts)
        when "OutputPartial"
          update_attribute_values_partial(attr_mh,update_deltas,opts)
        else #TODO: below is for legacy form befor had Output objects; may convert to Output form
        raise Errow.new("Need to refactor to handle use of source_output_id")
        update_select_ds = SQL::ArrayDataset.create(db,update_deltas,attr_mh,:convert_for_update => true)
        Model.update_from_select(attr_mh,FieldSet.new(:attribute,[:value_derived]),update_select_ds,opts)
      end
    end

    #appends value to any array type; if the array does not exist already it creates it from fresh
    def self.update_attribute_values_array_append(attr_mh,array_slice_rows,opts={})
      ret = Array.new
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
          
          replacement_row = {:id => attr_id, :value_derived => existing_val + r[:array_slice]}
          ret << replacement_row.merge(:source_output_id => r[:source_output_id], :old_value_derived => existing_val)
          replacement_row
        end
        attr_updates
      end

      #update the index_maps on the links
      Model.update_from_rows(attr_mh.createMH(:attribute_link),attr_link_updates)
      ret
    end

    def self.update_attribute_values_partial(attr_mh,partial_update_rows,opts={})
      index_map_list = partial_update_rows.map{|r|r[:index_map] unless r[:index_map_persisted]}.compact
      cmp_mh = attr_mh.createMH(:component)
      AttributeLink::IndexMap.resolve_input_paths!(index_map_list,cmp_mh)
      id_list = partial_update_rows.map{|r|r[:id]}

      ndx_ret = Hash.new
      Model.select_process_and_update(attr_mh,[:id,:value_derived],id_list) do |existing_vals|
        ndx_existing_vals = existing_vals.inject({}) do |h,r|
          h.merge(r[:id] => r[:value_derived])
        end
        partial_update_rows.each do |r|
          #TODO: more efficient if cast out elements taht did not change
          #TODO: need to validate that this works when theer are multiple nested values for same id
          attr_id = r[:id]
          existing_val = (ndx_ret[attr_id]||{})[:value_derived] || ndx_existing_vals[attr_id]
          p = ndx_ret[attr_id] ||= {
            :id => attr_id,
            :source_output_id => r[:source_output_id],
            :old_value_derived => ndx_existing_vals[attr_id]
          }
          p[:value_derived] = r[:index_map].merge_into(existing_val,r[:output_value])
        end
        #replacement rows
        ndx_ret.values.map{|r|Aux.hash_subset(r,[:id,:value_derived])}
      end

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

      ndx_ret.values
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
  end
end
