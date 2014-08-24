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

    # opts can have :parse => true
    def reify!(assembly,opts)
      if self[:attribute_settings]
        AttributeSettings.reify!(self[:attribute_settings],assembly,opts)
      end
      if self[:node_bindings]
        NodeBindings.reify!(self[:node_bindings],assembly,opts)
      end
      self
    end
  end
end
