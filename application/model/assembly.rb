module XYZ
  class Assembly < Component

    def is_assembly?()
      true
    end
    def assembly_type()
      #TODO: stub; may use basic_type to distinguish between component and node assemblies
      :node
    end
    def is_base_component?()
      nil
    end
    def get_component_with_attributes_unraveled(attr_filters={})
      attr_vc = "#{assembly_type()}_assembly_attributes".to_sym
      sp_hash = {:columns => [:id,:display_name,:component_type,:basic_type,attr_vc]}
      component_and_attrs = get_objects_from_sp_hash(sp_hash)
      return nil if component_and_attrs.empty?
      #TODO: hack until basic_type is populated
      #component = component_and_attrs.first.subset(:id,:display_name,:component_type,:basic_type)
      component = component_and_attrs.first.subset(:id,:display_name,:component_type).merge(:basic_type => "#{assembly_type()}_assembly")
      filtered_attrs = component_and_attrs.map{|r|r[:attribute] unless attribute_is_filtered?(r[:attribute],attr_filters)}.compact
      component.merge(:attributes => AttributeComplexType.flatten_attribute_list(filtered_attrs))
    end
  end
end
