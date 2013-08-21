module XYZ
  module ComponentModelDefProcessor
    def get_model_def(attr_filters={:hidden => true})
      cmp_attrs_obj = get_component_with_attributes_unraveled(attr_filters)
      ModelDefProcessorInternals.convert_to_model_def_form(cmp_attrs_obj)
    end

    def get_field_def(attr_filters={:hidden => true})
      get_model_def(attr_filters)[:columns]
    end

    def update_field_def(field_def_update)
      ModelDefProcessorInternals.update_field_def(self,field_def_update)
    end
   #TODO: cleanup uniform way of giving field def; for below just assuming hash display name
    def create_or_modify_field_def(field_def)
      ModelDefProcessorInternals.create_or_modify_field_def(self,field_def)
    end

  module ModelDefProcessorInternals
   extend R8Tpl::Utility::I18n

    #returns the list of idhs that have been created or modified
    def self.create_or_modify_field_def(component,field_def)
      attr_mh = component.model_handle.create_childMH(:attribute)
      attr_hash = Aux::hash_subset(field_def,CreateFields)
      unless attr_hash[:display_name]
        raise Error.new("display_name required in field_def")
      end
      attr_hash[:ref] = attr_hash[:display_name]
      attr_hash[:data_type] != "string"
      #TODO: may use a method rather than below that is more efficient; below returns alll children rather than filtered search
      Model.modify_children_from_rows(attr_mh,component.id_handle,[attr_hash],[:ref],:update_matching => true,:no_delete => true)
    end
    CreateFields = [{"display_name" => :display_name}, {"default" => :value_asserted}, {"data_type" => :data_type}]

    def self.update_field_def(component,field_def_update)
      #compute default 
      default_assign = AttributeComplexType.ravel_raw_post_hash({field_def_update["id"] => field_def_update["default"]},:attribute,component[:id]).first
      attr_mh = component.model_handle.createMH(:attribute)
      attr_hash = Aux::hash_subset(field_def_update,UpdateFields - %w{default i18n}).merge(default_assign)
      Model.update_from_rows(attr_mh,[attr_hash],:partial_value => true)

      field_def = field_def_update["field_def"]
      #update label
      #TODO: if now if whether cahnged can be more efficient
      label = field_def_update["i18n"]
      component.update_attribute_i18n_label(field_def["name"],label) if label
      field_def.merge(Aux::hash_subset(field_def_update,UpdateFields))
    end
    UpdateFields = %w{default description required, i18n}

    def self.convert_to_model_def_form(cmp_attrs_obj)
      component_i18n = cmp_attrs_obj.get_component_i18n_label()
      ret = Aux::ordered_hash_subset(cmp_attrs_obj,ComponentMappings){|v|v.kind_of?(String) ? v.to_sym : v}

      ret[:columns] = cmp_attrs_obj[:attributes].map do |attr|
        attr_i18n = cmp_attrs_obj.get_attribute_i18n_label(attr)
        seed = {:i18n => attr_i18n, :component_i18n => component_i18n}
        opts = {:include_virtual_columns => true,:seed => seed}
        Aux::ordered_hash_subset(attr,ColumnMappings,opts) do |k,v|
          convert_value_if_needed(k,v,attr)
        end
      end
      ret
    end
=begin
    def self.convert_to_model_def_form(cmp_attrs_obj)
      i18n = get_i18n_mappings_for_models(:attribute,:component)
      component_type = cmp_attrs_obj[:component_type] 
      ret = Aux::ordered_hash_subset(cmp_attrs_obj,ComponentMappings){|v|v.kind_of?(String) ? v.to_sym : v}

      ret[:columns] = cmp_attrs_obj[:attributes].map do |col_info|
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
=end
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
