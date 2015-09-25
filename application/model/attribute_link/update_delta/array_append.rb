module DTK; class AttributeLink
  class UpdateDelta
    class ArrayAppend < self
      # appends value to any array type; if the array does not exist already it creates it from fresh
      def self.update_attribute_values(attr_mh, update_deltas, _opts = {})
        ndx_ret = {}
        attr_link_updates = []
        id_list = update_deltas.map { |r| r[:id] }
        Model.select_process_and_update(attr_mh, [:id, :value_derived], id_list) do |existing_vals|
          ndx_existing_vals = existing_vals.inject({}) { |h, r| h.merge(r[:id] => r[:value_derived]) }

          ndx_attr_updates = update_deltas.inject({}) do |h, update_delta|
            attr_id = update_delta[:id]
            existing_val = ndx_existing_vals[attr_id] || []
            offset = existing_val.size
            last_el = update_delta[:array_slice].size - 1
            index_map = (update_delta[:output_is_array] ? IndexMap.generate_from_bounds(0, last_el, offset) : IndexMap.generate_for_output_scalar(last_el, offset))
            
            attr_link_update = {
              id: update_delta[:attr_link_id],
              index_map: index_map
            }
            attr_link_updates << attr_link_update
            
            # update ndx_existing_vals to handle case where  multiple entries pointing to same element
            ndx_existing_vals[attr_id] = new_val = existing_val + update_delta[:array_slice]
            replacement_row = { id: attr_id, value_derived: new_val }
            
            # if multiple entries pointing to same element then last one taken since it incorporates all of them
            
            # TODO: if multiple entries pointing to same element source_output_id will be the last one;
            # this may be be problematic because source_output_id may be used just for parent to use for change
            # objects; double check this
            ndx_ret.merge!(attr_id => replacement_row.merge(source_output_id: update_delta[:source_output_id], old_value_derived: existing_val))
            h.merge(attr_id => replacement_row)
          end
          # ndx_attr_updates.values is vaule that is used for update in select_process_and_update
          ndx_attr_updates.values
        end

        # update the index_maps on the links
        Model.update_from_rows(attr_mh.createMH(:attribute_link), attr_link_updates)
        ndx_ret.values
      end
    end
  end
end; end

