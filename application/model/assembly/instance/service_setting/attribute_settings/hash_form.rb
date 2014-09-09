module DTK; class ServiceSetting
  class AttributeSettings
    class HashForm < self
      def self.apply_from_hash_content(assembly,hash_content)
        pp hash_content
        raise Error.new("Got here")
        new(hash_content).apply_settings(assembly)
      end

      def self.get_and_render_in_hash_form(assembly,opts={})
        attrs = assembly.get_attributes_raw_print_form(opts)
        render_in_hash_form(attrs)
      end

     private
      def self.render_in_hash_form(raw_attrs)
        # merge the node and component attributes in a nested structure
        ndx_attrs = Hash.new
        raw_attrs.node_attrs.each do |node_attr|
          node_info = ndx_attrs[node_attr[:node][:display_name]]||= {:attrs => Hash.new,:cmps => Hash.new}
          node_info[:attrs].merge!(node_attr[:display_name] => node_attr[:attribute_value])
        end
        raw_attrs.component_attrs.each do |cmp_attr|
          node_info = ndx_attrs[cmp_attr[:node][:display_name]]||= {:attrs => Hash.new,:cmps => Hash.new}
          cmp_info = node_info[:cmps][cmp_attr[:nested_component][:display_name]]||= Hash.new
          cmp_info.merge!(cmp_attr[:display_name] => cmp_attr[:attribute_value])
        end
        
        # put assembly attributes in ret
        ret = raw_attrs.assembly_attrs.sort{|a,b|a[:display_name] <=> b[:display_name]}.inject(SimpleOrderedHash.new) do |h,attr|
          h.merge(attr[:display_name] => attr[:attribute_value])
        end

        # put node and component attributes in ret
        ndx_attrs.keys.sort().each do |node_name|
          ret_node_pntr = ret["#{node_name}#{ContextDelim}"] = SimpleOrderedHash.new
          node_info = ndx_attrs[node_name]
          node_info[:attrs].keys.sort.each do |attr_name|
            ret_node_pntr.merge!(attr_name => node_info[:attrs][attr_name])
          end
          node_info[:cmps].keys.sort.each do |cmp_name|
            ret_cmp_pntr = ret_node_pntr["#{cmp_name}#{ContextDelim}"] = SimpleOrderedHash.new
            cmp_info = node_info[:cmps][cmp_name]
            cmp_info.keys.sort.each do |attr_name|
              ret_cmp_pntr.merge!(attr_name => cmp_info[attr_name])
            end
          end
        end
        ret
      end

    end
  end
end; end
