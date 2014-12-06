module DTK; class Attribute
  class UpdateDerivedValues
    r8_nested_require('update_derived_values','delete')
    module ClassMixin
      ::DTK::Attribute::LinkDeleteInfo = UpdateDerivedValues::Delete::LinkInfo
      # links_delete_info has type array of Delete::LinkInfo
      def update_attributes_for_delete_links(attr_mh,links_delete_info)
        UpdateDerivedValues.update_for_delete_links(attr_mh,links_delete_info)
      end
    end

    def self.update(attr_mh,update_deltas,opts={})
      ret = Array.new
      attr_ids = update_deltas.map{|r|r[:id]}
      critical_section(attr_ids) do
        ret = update_in_critical_section(attr_mh,update_deltas,opts={})
      end
      ret
    end

    # links_delete_info has type array of Delete::LinkInfo
    def self.update_for_delete_links(attr_mh,links_delete_info)
      ret = Array.new
      attr_ids = links_delete_info.map{|l|l.input_attribute[:id]}
      critical_section(attr_ids) do
        ret = links_delete_info.map{|link_info|Delete.update_attribute(attr_mh,link_info)}
      end
      ret
    end

   private
    Lock = Mutex.new
    def self.critical_section(attr_ids,&block)
      # passing in attr_ids, but not using now; may use if better to lock on per attribute basis
      Lock.synchronize{yield}
    end

    def self.update_in_critical_section(attr_mh,update_deltas,opts={})
      # break up by type of row and process and aggregate
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

    def self.update_attribute_values_aux(type,attr_mh,update_deltas,opts={})
      case type
        when "OutputArrayAppend"
          update_attribute_values_array_append(attr_mh,update_deltas,opts)
        when "OutputPartial"
          update_attribute_values_partial(attr_mh,update_deltas,opts)
        else 
          update_attribute_values_simple(attr_mh,update_deltas,opts)
      end
    end

    def self.update_attribute_values_simple(attr_mh,update_hashes,opts={})
      ret = Array.new
      id_list = update_hashes.map{|r|r[:id]}
      Model.select_process_and_update(attr_mh,[:id,:value_derived],id_list) do |existing_vals|
        ndx_existing_vals = existing_vals.inject({}){|h,r|h.merge(r[:id] => r[:value_derived])}
        update_hashes.map do |r|
          attr_id = r[:id]
          existing_val = ndx_existing_vals[attr_id]
          replacement_row = {:id => attr_id, :value_derived => r[:value_derived]}
          ret << replacement_row.merge(:source_output_id => r[:source_output_id], :old_value_derived => existing_val)
          replacement_row
        end
      end
      ret
    end

    # appends value to any array type; if the array does not exist already it creates it from fresh
    def self.update_attribute_values_array_append(attr_mh,array_slice_rows,opts={})
      ndx_ret = Hash.new
      attr_link_updates = Array.new
      id_list = array_slice_rows.map{|r|r[:id]}
      Model.select_process_and_update(attr_mh,[:id,:value_derived],id_list) do |existing_vals|
        ndx_existing_vals = existing_vals.inject(Hash.new){|h,r|h.merge(r[:id] => r[:value_derived])}
        ndx_attr_updates = array_slice_rows.inject(Hash.new) do |h,r|
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

          # update ndx_existing_vals to handle case where  multiple entries pointing to same element
          ndx_existing_vals[attr_id] = new_val = existing_val + r[:array_slice]
          replacement_row = {:id => attr_id, :value_derived => new_val}

          # if multiple entries pointing to same element then last one taken since it incorporates all of them  

          # TODO: if multiple entries pointing to same element source_output_id will be the last one; 
          # this may be be problematic because source_output_id may be used just for parent to use for change
          # objects; double check this
          ndx_ret.merge!(attr_id => replacement_row.merge(:source_output_id => r[:source_output_id], :old_value_derived => existing_val))
          h.merge(attr_id => replacement_row)
        end
        ndx_attr_updates.values
      end

      # update the index_maps on the links
      Model.update_from_rows(attr_mh.createMH(:attribute_link),attr_link_updates)
      ndx_ret.values
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
          # TODO: more efficient if cast out elements taht did not change
          # TODO: need to validate that this works when theer are multiple nested values for same id
          attr_id = r[:id]
          existing_val = (ndx_ret[attr_id]||{})[:value_derived] || ndx_existing_vals[attr_id]
          p = ndx_ret[attr_id] ||= {
            :id => attr_id,
            :source_output_id => r[:source_output_id],
            :old_value_derived => ndx_existing_vals[attr_id]
          }
          p[:value_derived] = r[:index_map].merge_into(existing_val,r[:output_value])
        end
        # replacement rows
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
      ret = nil
      index_map = link_hash[:index_map]
      return ret unless index_map 
      unless index_map.size == 1
        Log.error("not treating update_for_delete_link when index_map size is unequal to 1; its value is #{index_map.inspect}")
        return ret
      end   
      index_map.first && index_map.first[dir]
    end


  end
end; end
