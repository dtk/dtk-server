# TODO: Marked for removal [Haris] - Move logic to other controller
module DTK
  class AttributeController < AuthController

    def rest__set()
      attr_type = ret_non_null_request_params(:attribute_type)
      attribute_id, attribute_value, module_id = ret_non_null_request_params(:attribute_id, :attribute_value, "#{attr_type}_id".to_sym)
      attribute_instance = Attribute.get_attribute_from_identifier(attribute_id, model_handle(), module_id)
      # attribute_instance = id_handle(attribute_id, :attribute).create_object(:model_name => :attribute)
      attribute_instance.set_attribute_value(attribute_value)

      rest_ok_response(:attribute_id => attribute_id)
    end

  end
end
