module XYZ
  class ModelDefProcessor
    extend R8Tpl::Utility::I18n
    def self.get(id_handle,opts={})
      cmp_attrs_objs = id_handle.create_object().get_component_with_attributes_unraveled()
      convert_to_model_def_form(cmp_attrs_objs)
    end
    private 
    def self.convert_to_model_def_form(cmp_attrs_objs)
      i18n = get_i18n_mappings_for_models(:attribute)
      component_type = cmp_attrs_objs[:component_type] 
      ret = Aux::ordered_hash_subset(cmp_attrs_objs,ComponentMappings){|v|v.kind_of?(String) ? v.to_sym : v}

      ret[:columns] = cmp_attrs_objs[:attributes].map do |col_info|
        i18n_string = i18n_string(i18n,:attribute,col_info[:display_name],component_type)
        opts = {:include_virtual_columns => true,:seed => {:i18n => i18n_string}}
        Aux::ordered_hash_subset(col_info,ColumnMappings,opts) do |k,v|
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
       {:dynamic => :read_only},
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
