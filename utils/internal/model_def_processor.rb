module XYZ
  class ModelDefProcessor
    def self.get_component(id_handle,opts={})
      cmp_attrs_objs = id_handle.create_object().get_component_with_attributes_unraveled()
pp [:cmp_attrs_objs,cmp_attrs_objs]
      convert_to_model_def_form(cmp_attrs_objs)
    end
    private 
    def self.convert_to_model_def_form(cmp_attrs_objs)
      ret = Aux::ordered_hash_subset(cmp_attrs_objs,ComponentMappings){|v|v.kind_of?(String) ? v.to_sym : v}

      ret[:columns] = cmp_attrs_objs[:attributes].inject({}) do |h,col_info|
        converted_col_info = Aux::ordered_hash_subset(col_info,ColumnMappings) do |k,v|
          convert_value_if_needed(k,v,col_info)
        end
        h.merge(col_info[:display_name].to_sym => converted_col_info)
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
       {:attribute_value => :default},
       :size,
       :required,
       :dynamic,
       :cannot_change,
       #TODO: not for unraveled :semantic_type_summary,
       #TODO: not for :semantic_type
      ]
  
    def self.convert_value_if_needed(k,v,col_info)
      case k
        when :type then v.to_sym
        when :default then type_convert_value(v,col_info[:data_type]) #data_type not tupe because cold_info not converted
        else v
      end
    end
    def self.type_convert_value(v,type)
      return nil if v.nil?
      case type && type.to_sym
        when :integer then v.to_i
        else v
      end
    end
  end
end
