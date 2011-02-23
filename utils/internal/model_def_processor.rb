module XYZ
  class ModelDefProcessor
    def self.get(id_handle,opts={})
      cmp_attrs_objs = id_handle.create_object().get_component_with_attributes_unraveled()
      convert_to_model_def_form(cmp_attrs_objs)
    end
    private 
    def self.convert_to_model_def_form(cmp_attrs_objs)
      ret = Aux::ordered_hash_subset(cmp_attrs_objs,ComponentMappings){|v|v.kind_of?(String) ? v.to_sym : v}

      ret[:columns] = cmp_attrs_objs[:attributes].map do |col_info|
        Aux::ordered_hash_subset(col_info,ColumnMappings,:include_virtual_columns => true) do |k,v|
          convert_value_if_needed(k,v,col_info)
        end
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
       {:display_name => :name},
       {:unraveled_attribute_id => :id},
       {:data_type => :type},
       {:attribute_value => :default},
       :required,
       :dynamic,
       :cannot_change
      ]
  
    def self.convert_value_if_needed(k,v,col_info)
      case k
        when :type then v.to_sym
        when :default then type_convert_value(v,col_info[:data_type]) 
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
