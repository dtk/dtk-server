module DTK; class AttributeLink
  class UpdateDelta
    class Simple
      def self.update_attribute_values(attr_mh, update_hashes, _opts = {})
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
    end
  end
end; end
