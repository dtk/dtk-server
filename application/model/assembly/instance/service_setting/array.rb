module DTK
  class ServiceSetting
    class Array < ::Array
      def apply_settings(assembly)
        each{|setting|setting.apply_setting(assembly)}
      end
    end
  end
end

