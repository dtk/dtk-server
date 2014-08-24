module DTK
  class ServiceSetting < Model
    r8_nested_require('service_setting','array')
    r8_nested_require('service_setting','attribute_settings')
    r8_nested_require('service_setting','node_bindings')
    
    def self.common_columns()
      [
       :id,
       :display_name,
       :group_id,
       :node_bindings,
       :attribute_settings
      ]
    end
    
    def apply_setting(target,assembly)
      reify!()
      if settings = self[AttributeSettingsField]
        settings.apply_settings(assembly)
      end
      if node_bindings = self[NodeBindingsField]
        node_bindings.set_node_bindings(target,assembly)
      end
    end

    def reify!()
      reify_field!(AttributeSettingsField,AttributeSettings)
      reify_field!(NodeBindingsField,NodeBindings)      
    end
    AttributeSettingsField = :attribute_settings
    NodeBindingsField = :node_bindings
   private
    def reify_field!(field,klass)
      if content = self[field]
        unless content.kind_of?(klass)
          reified = klass.new()
          klass.each_element(content){|el|reified << el}
          self[field] = reified
        end
      end
    end
  end
end
