module DTK
  class ServiceSetting
    class AttributeSettings < Array
      def self.each_element(content,attr_prefix=nil,&block)
        content.each_pair do |key,body|
          if key =~ Regexp.new("(^.+)#{ContextDelim}$")
            attr_part = $1
            nested_attr_prefix = compose_attr(attr_prefix,attr_part)
            each_element(body,nested_attr_prefix,&block)
          else
            attr = compose_attr(attr_prefix,key)
            value = body
            block.call(Element.new(attr,value))
          end
        end
      end
      ContextDelim = '/'
     private
      def self.compose_attr(attr_prefix,attr_part)
        attr_prefix ? "#{attr_prefix}#{AttrPartDelim}#{attr_part}" : attr_part
      end
      AttrPartDelim = '/'

      class Element
        def initialize(attribute,value)
          @attribute = attribute
          @value = value
        end
      end
    end
  end
end
