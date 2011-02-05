module XYZ
  class ModelDefProcessor
    def self.get_component(id_handle,opts={})
      cmp_attrs_objs = id_handle.create_object().get_component_with_attributes_unraveled()
pp [:cmp_attrs_objs,cmp_attrs_objs]
      convert_to_model_def_form(cmp_attrs_objs)
    end
    private 
    def self.convert_to_model_def_form(cmp_attrs_objs)
      ret = Aux::ordered_hash_subset(cmp_attrs_objs,ComponentMappings){|x|x.kind_of?(String) ? x.to_sym : x}

      ret[:columns] = cmp_attrs_objs[:attributes].inject({}) do |h,col|
        col_info = Aux::ordered_hash_subset(col,ColumnMappings)
        h.merge(col[:display_name].to_sym => col_info)
      end
      ret
    end
                           
    ComponentMappings =
      [
       {:component_type => :model_name},
       :id
      ]
    ColumnMappings = 
      [
       {:data_type => :type},
       {:default => :attribute_value},
       :size,
       :required,
       :dynamic,
       :cannot_change,
       #TODO: not for unraveled :semantic_type_summary,
       #TODO: not for :semantic_type
      ]
  end
end
