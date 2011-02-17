module XYZ
  class Assembly < Component

    def is_assembly?()
      true
    end
    def is_base_component?()
      nil
    end

    def get_attributes_unraveled()
      rows = get_objects_from_sp_hash(:columns => [:assembly_unravel_attributes])
pp [:unraveld_assembly_rows,rows]
=begin
      flattened_attr_list = AttributeComplexType.flatten_attribute_list(raw_attributes)
      i18n = get_i18n_mappings_for_models(:attribute)
      flattened_attr_list.map do |a|
        name = a[:display_name]
        {
          :id => a[:unraveled_attribute_id],
          :name =>  name,
          :value => a[:attribute_value],
          :i18n => i18n_string(i18n,:attribute,name)
        }
      end
=end
    end
  end
end
