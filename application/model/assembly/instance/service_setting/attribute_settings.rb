module DTK
  class ServiceSetting
    class AttributeSettings < Array
      r8_nested_require('attribute_settings','hash_form')

      def apply_settings(assembly)
        av_pairs = map{|el|el.av_pair_form()}
        assembly.set_attributes(av_pairs)
      end

      ContextDelim = '/'
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

     private
      AttrPartDelim = '/'
      def self.compose_attr(attr_prefix,attr_part)
        attr_prefix ? "#{attr_prefix}#{AttrPartDelim}#{attr_part}" : attr_part.to_s
      end

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
  end
end
