module XYZ
  class Layout < Model
    def self.create_and_save_from_field_def(model_handle,field_def)
    end
   private
    def self.layout_def_from_field_def(field_def)
    end

    def self.group_name(field_def_el)
      if field_def_el[:node_name]
        "#{field_def_el[:node_name]}/#{field_def_el[:component_type]}"
      else
        field_def_el[:component_i18n]
      end
    end
  end
end
