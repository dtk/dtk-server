module DTK; class AttributeLink::UpdateDelta::Delete
  class Index
    class Null < self
      # called when the last index being removed
      def process!
        input_attribute = @link_info.input_attribute
        row_to_update = {
          id: input_attribute[:id],
          value_derived: nil
        }
        Model.update_from_rows(@attr_mh, [row_to_update])
        old_value_derived = input_attribute[:value_derived]
        row_to_update.merge(old_value_derived: old_value_derived)
      end
    end
  end
end; end
