module DTK
  class ServiceSetting < Model
    def self.common_columns()
      [
        :id,
        :display_name
      ]
    end
  end
end