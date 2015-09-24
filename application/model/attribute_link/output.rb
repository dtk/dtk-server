module DTK; class AttributeLink
  class Output < HashObject
    def self.update_attribute_values_simple(attr_mh, update_hashes, _opts = {})
      ret = []
      id_list = update_hashes.map { |r| r[:id] }
      Model.select_process_and_update(attr_mh, [:id, :value_derived], id_list) do |existing_vals|
        ndx_existing_vals = existing_vals.inject({}) { |h, r| h.merge(r[:id] => r[:value_derived]) }
        update_hashes.map do |r|
          attr_id = r[:id]
          existing_val = ndx_existing_vals[attr_id]
          replacement_row = { id: attr_id, value_derived: r[:value_derived] }
          ret << replacement_row.merge(source_output_id: r[:source_output_id], old_value_derived: existing_val)
          replacement_row
        end
      end
      ret
    end

    class ArrayAppend < self
      # appends value to any array type; if the array does not exist already it creates it from fresh
      def self.update_attribute_values(attr_mh, array_slice_rows, _opts = {})
        ndx_ret = {}
        attr_link_updates = []
        id_list = array_slice_rows.map { |r| r[:id] }
        Model.select_process_and_update(attr_mh, [:id, :value_derived], id_list) do |existing_vals|
          ndx_existing_vals = existing_vals.inject({}) { |h, r| h.merge(r[:id] => r[:value_derived]) }
          ndx_attr_updates = array_slice_rows.inject({}) do |h, r|
            attr_id = r[:id]
            existing_val = ndx_existing_vals[attr_id] || []
            offset = existing_val.size
            last_el = r[:array_slice].size - 1
            index_map = (r[:output_is_array] ? IndexMap.generate_from_bounds(0, last_el, offset) : IndexMap.generate_for_output_scalar(last_el, offset))
            
            attr_link_update = {
              id: r[:attr_link_id],
              index_map: index_map
            }
            attr_link_updates << attr_link_update
            
            # update ndx_existing_vals to handle case where  multiple entries pointing to same element
            ndx_existing_vals[attr_id] = new_val = existing_val + r[:array_slice]
            replacement_row = { id: attr_id, value_derived: new_val }
            
            # if multiple entries pointing to same element then last one taken since it incorporates all of them
            
            # TODO: if multiple entries pointing to same element source_output_id will be the last one;
            # this may be be problematic because source_output_id may be used just for parent to use for change
            # objects; double check this
            ndx_ret.merge!(attr_id => replacement_row.merge(source_output_id: r[:source_output_id], old_value_derived: existing_val))
            h.merge(attr_id => replacement_row)
          end
          ndx_attr_updates.values
        end

        # update the index_maps on the links
        Model.update_from_rows(attr_mh.createMH(:attribute_link), attr_link_updates)
        ndx_ret.values
      end

    end
    
    class Partial < self
      def self.update_attribute(attr_mh, partial_update_rows, _opts = {})
        index_map_list = partial_update_rows.map { |r| r[:index_map] unless r[:index_map_persisted] }.compact
        cmp_mh = attr_mh.createMH(:component)
        AttributeLink::IndexMap.resolve_input_paths!(index_map_list, cmp_mh)
        id_list = partial_update_rows.map { |r| r[:id] }
        
        ndx_ret = {}
        Model.select_process_and_update(attr_mh, [:id, :value_derived], id_list) do |existing_vals|
          ndx_existing_vals = existing_vals.inject({}) do |h, r|
            h.merge(r[:id] => r[:value_derived])
          end
          partial_update_rows.each do |r|
            # TODO: more efficient if cast out elements taht did not change
            # TODO: need to validate that this works when theer are multiple nested values for same id
            attr_id = r[:id]
            existing_val = (ndx_ret[attr_id] || {})[:value_derived] || ndx_existing_vals[attr_id]
            p = ndx_ret[attr_id] ||= {
              id: attr_id,
              source_output_id: r[:source_output_id],
              old_value_derived: ndx_existing_vals[attr_id]
            }
            p[:value_derived] = r[:index_map].merge_into(existing_val, r[:output_value])
          end
          # replacement rows
          ndx_ret.values.map { |r| Aux.hash_subset(r, [:id, :value_derived]) }
        end
        
        attr_link_updates = partial_update_rows.map do |r|
          unless r[:index_map_persisted]
            {
              id: r[:attr_link_id],
              index_map: r[:index_map]
            }
          end
        end.compact
        unless attr_link_updates.empty?
          Model.update_from_rows(attr_mh.createMH(:attribute_link), attr_link_updates)
        end
        
        ndx_ret.values
      end
    end
  end
end; end

