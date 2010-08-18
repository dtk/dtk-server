module XYZ
  class AttributeController < MainController
    def self.field_set()
      [
        :id,
        :display_name,
        :external_attr_ref,
        :attribute_value,
        :description,
        :parent_id,
        :parent_path
      ]   
    end
  end
end
