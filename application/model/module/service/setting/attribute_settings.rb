module DTK
  class ServiceSetting
    class AttributeSettings
      def self.reify!(obj,assembly,opts={})
        unless obj.kind_of?(AttributeSettings)
          pp ['AttributeSettings.reify!',obj,opts]
          obj
        end
      end
    end
  end
end
