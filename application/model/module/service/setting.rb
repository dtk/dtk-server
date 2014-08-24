module DTK
  class ServiceSetting < Model
    r8_nested_require('setting','array')
    r8_nested_require('setting','attribute_settings')
    r8_nested_require('setting','node_bindings')

    def self.common_columns()
      [
        :id,
        :display_name,
        :group_id,
        :node_bindings,
        :attribute_settings
      ]
    end

    def apply_setting(assembly)
      reify!(assembly)
      if settings = self[:attribute_settings]
        settings.apply_settings(assembly)
      end
    end
   private
    # opts can have :parse => true
    def reify!(assembly)
      reify_field!(:attribute_settings,AttributeSettings,assembly)
pp self[:attribute_settings]
      reify_field!(:node_bindings,NodeBindings,assembly)
      self
    end

    def reify_field!(field,klass,assembly)
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
