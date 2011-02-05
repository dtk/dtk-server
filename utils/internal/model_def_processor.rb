module XYZ
  class ModelDefProcessor
    def self.get_component(id_handle,opts={})
      #TODO:get_component_with_attributes_unraveled gives values as well as meta information. More efficient to have variant that just deals with meta information; a caveat is if rendering default as value_asserted
      id_handle.create_object().get_component_with_attributes_unraveled()
    end
  end
end
