module DTK
  class ServiceSetting
    class NodeBindings
      def self.reify!(obj,assembly,opts={})
        unless obj.kind_of?(AttributeSettings)
          pp ['NodeBindings.reify!',obj,opts]
          obj
        end
      end
    end
  end
end
