module DTK
  class ServiceSetting < Model
    def self.common_columns()
      [
        :id,
        :display_name,
        :group_id,
        :node_bindings,
        :attribute_settings
      ]
    end
  end
end
