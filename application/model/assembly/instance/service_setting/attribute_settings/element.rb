module DTK; class ServiceSetting
  class AttributeSettings
    class Element
      def initialize(attribute_path,raw_value)
        @attribute_path = attribute_path
        @raw_value = raw_value
      end
      def av_pair_form()
        {:pattern => @attribute_path,:value => value()}
      end
      def value()
        if @raw_value.kind_of?(Hash) or  @raw_value.kind_of?(Array)
          @raw_value
        else
          @raw_value.to_s
        end
      end
    end
  end
end; end
