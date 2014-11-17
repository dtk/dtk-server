module DTK
  class ServiceModule; class AssemblyExport
    r8_require('v3')
    class V4 < V3
      def attr_overrides_output_form(non_def_attrs)
        ret = nil
        return ret unless non_def_attrs
        value_overrides = Array.new
        attribute_info = Array.new
        non_def_attrs.values.each do |attr|
          if attr.isa_value_override?()
            unless attr.is_title_attribute()
              value_overrides << {attr[:display_name] => attr_value_output_form(attr,:attribute_value)}
            end
          end
          if base_tags = attr.base_tags?()
            attribute_info << {attr[:display_name] => attr_tags_setting(base_tags)}
          end
        end

        ret = attribute_info_ouput_form(:attributes,value_overrides).merge(
               attribute_info_ouput_form(:attribute_info,attribute_info))
        !ret.empty? && ret
      end

      def attr_tags_setting(tags)
        tags.size == 1 ? {:tag => tags.first} : {:tags => tags}
      end

      def attribute_info_ouput_form(key,array)
        if array.empty?
          Hash.new
        else
          sorted = array.sort{|a,b|a.keys.first <=> b.keys.first}
          SimpleOrderedHash.new(key => SimpleOrderedHash.new(sorted))
        end
      end
    end
  end; end
end

