module DTK; class AttributeLink
  class UpdateDelta
    class Simple
      def self.update_attribute_values(attr_mh, update_deltas, _opts = {})
        ret = []
        id_list = update_deltas.map { |r| r[:id] }
        Model.select_process_and_update(attr_mh, [:id, :value_derived], id_list) do |existing_vals|
          ndx_existing_vals = existing_vals.inject({}) { |h, r| h.merge(r[:id] => r[:value_derived]) }
          update_deltas.map do |update_delta|
            attr_id = update_delta[:id]
            existing_val = ndx_existing_vals[attr_id]
            replacement_row = { id: attr_id, value_derived: update_delta[:value_derived] }
            ret << replacement_row.merge(source_output_id: update_delta[:source_output_id], old_value_derived: existing_val)
            replacement_row
          end
        end
        ret
      end
    end
  end
end; end
