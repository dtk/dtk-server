module DTK
  class ServiceSetting
    class Array < ::Array
      def apply_settings(target, assembly)
        each { |setting| setting.apply_setting(target, assembly) }
      end
    end
  end
end
