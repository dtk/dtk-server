module DTK; class ServiceSetting
  class AttributeSettings
    class HashForm < self
      def self.render(all_attrs_struct)
        render_in_hash_form(all_attrs_struct)
      end

      private

      ContextDelim = '/'
      def self.each_element(settings_hash,attr_prefix=nil,&block)
        settings_hash.each_pair do |key,body|
          if key =~ Regexp.new("(^.+)#{ContextDelim}$")
            attr_part = $1
            nested_attr_prefix = compose_attr(attr_prefix,attr_part)
            if body.is_a?(Hash)
              each_element(body,nested_attr_prefix,&block)
            else
              Log.error_pp(["Unexpected form in AttributeSettings::HashForm.each_element:",key,body, "ignoring; should be caught in better parsing of settings"])
            end
          else
            attr = compose_attr(attr_prefix,key)
            value = body
            block.call(Element.new(attr,value))
          end
        end
      end

      AttrPartDelim = '/'
      def self.compose_attr(attr_prefix,attr_part)
        attr_prefix ? "#{attr_prefix}#{AttrPartDelim}#{attr_part}" : attr_part.to_s
      end

      def self.render_in_hash_form(all_attrs_struct)
        # merge the node and component attributes in a nested structure
        ndx_attrs = {}
        all_attrs_struct.node_attrs.each do |node_attr|
          # do not display node_attributes for assembly_wide node
          next if node_attr[:node][:type].eql?('assembly_wide')

          node_info = ndx_attrs[node_attr[:node][:display_name]]||= {attrs: {},cmps: {}}
          node_info[:attrs].merge!(node_attr[:display_name] => attribute_value(node_attr))
        end
        all_attrs_struct.component_attrs.each do |cmp_attr|
          node_info = ndx_attrs[cmp_attr[:node][:display_name]]||= {attrs: {},cmps: {}}
          cmp_print_name = cmp_attr[:nested_component].display_name_print_form()
          cmp_info = node_info[:cmps][cmp_print_name] ||= {}
          cmp_info.merge!(cmp_attr[:display_name] => attribute_value(cmp_attr))
        end
        
        # put assembly attributes in ret
        ret = all_attrs_struct.assembly_attrs.sort{|a,b|a[:display_name] <=> b[:display_name]}.inject(SimpleOrderedHash.new) do |h,attr|
          h.merge(attr[:display_name] => attribute_value(attr))
        end

        # put node and component attributes in ret
        ndx_attrs.keys.sort().each do |node_name|
          is_assembly_wide = all_attrs_struct.node_attrs.find{|node| node[:node][:type].eql?('assembly_wide')} if node_name.eql?('assembly_wide')

          if is_assembly_wide
            ret_node_pntr = ret['components'] = SimpleOrderedHash.new
          else
            ret['nodes'] ||= {}
            ret_node_pntr = ret['nodes']["#{node_name}#{ContextDelim}"] = SimpleOrderedHash.new
          end

          node_info = ndx_attrs[node_name]
          node_info[:attrs].keys.sort.each do |attr_name|
            ret_node_pntr['attributes'] ||= {}
            ret_node_pntr['attributes'].merge!(attr_name => node_info[:attrs][attr_name])
          end

          node_info[:cmps].keys.sort.each do |cmp_name|
            if is_assembly_wide
              ret_cmp_pntr = ret_node_pntr["#{cmp_name}#{ContextDelim}"] = SimpleOrderedHash.new
            else
              ret_node_pntr['components'] ||= {}
              ret_cmp_pntr = ret_node_pntr['components']["#{cmp_name}#{ContextDelim}"] = SimpleOrderedHash.new
            end
            cmp_info = node_info[:cmps][cmp_name]
            ret_cmp_pntr['attributes'] ||= {}
            cmp_info.keys.sort.each do |attr_name|
              ret_cmp_pntr['attributes'].merge!(attr_name => cmp_info[attr_name])
            end
          end
        end
        return ret unless ret['components']

        # put assembly wide components on top
        cmps = ret.delete('components')
        ndx_ret = {'components' => cmps}.merge(ret)
      end

      def self.attribute_value(attr)
        attr.convert_value_to_ruby_object()
      end
    end
  end
end; end
