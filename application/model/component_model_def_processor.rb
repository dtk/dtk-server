module XYZ
  module ComponentModelDefProcessor
    def get_model_def(attr_filters={:hidden => true})
      cmp_attrs_objs = get_component_with_attributes_unraveled(attr_filters)
      ModelDefProcessorInternals.convert_to_model_def_form(cmp_attrs_objs)
    end

    def get_field_def(attr_filters={:hidden => true})
      get_model_def(attr_filters)[:columns]
    end

    def update_field_def(field_def_update)
      ModelDefProcessorInternals.update_field_def(self,field_def_update)
    end

  module ModelDefProcessorInternals
    extend R8Tpl::Utility::I18n

    def self.update_field_def(component,field_def_update)
      #compute default 
      attribute_rows = AttributeComplexType.ravel_raw_post_hash({field_def_update["id"] => field_def_update["default"]},:attribute,component[:id])
      pp [:attribute_rows,field_def_update["name"],attribute_rows]
      field_def_update["field_def"].merge("default" => field_def_update["default"])
    end

    def self.convert_to_model_def_form(cmp_attrs_objs)
      i18n = get_i18n_mappings_for_models(:attribute,:component)
      component_type = cmp_attrs_objs[:component_type] 
      ret = Aux::ordered_hash_subset(cmp_attrs_objs,ComponentMappings){|v|v.kind_of?(String) ? v.to_sym : v}

      ret[:columns] = cmp_attrs_objs[:attributes].map do |col_info|
        i18n_attr = i18n_string(i18n,:attribute,col_info[:display_name],component_type)
        i18n_component = i18n_string(i18n,:component,col_info[:component_name])
        seed = {:i18n => i18n_attr, :component_i18n => i18n_component}
        opts = {:include_virtual_columns => true,:seed => seed}
        Aux::ordered_hash_subset(col_info,ColumnMappings,opts) do |k,v|
          convert_value_if_needed(k,v,col_info)
        end
      end
      ret
    end
   private
    ComponentMappings =
      [
       {:component_type => :model_name},
       :id
      ]
    ColumnMappings = 
      [
       :node_id,
       :node_name,
       :component_type,
       {:component_component_id => :component_id},
       {:display_name => :name},
       {:unraveled_attribute_id => :id},
       :description,
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
end
