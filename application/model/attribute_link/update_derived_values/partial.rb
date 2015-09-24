module DTK; class AttributeLink
  class UpdateDerivedValues
    class Partial < self
      def self.update_attribute_values(attr_mh, partial_update_rows, _opts = {})
        index_map_list = partial_update_rows.map { |r| r[:index_map] unless r[:index_map_persisted] }.compact
        cmp_mh = attr_mh.createMH(:component)
        IndexMap.resolve_input_paths!(index_map_list, cmp_mh)
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

