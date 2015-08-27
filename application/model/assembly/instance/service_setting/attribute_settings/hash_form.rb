module DTK; class ServiceSetting
  class AttributeSettings
    class HashForm < self
      def self.render(all_attrs_struct)
        render_in_hash_form(all_attrs_struct)
      end

      private

      ContextDelim = '/'
      def self.each_element(settings_hash, attr_prefix = nil, &block)
        settings_hash.each_pair do |key, body|
          if key =~ Regexp.new("(^.+)#{ContextDelim}$")
            attr_part = Regexp.last_match(1)
            nested_attr_prefix = compose_attr(attr_prefix, attr_part)
            if body.is_a?(Hash)
              each_element(body, nested_attr_prefix, &block)
            else
              Log.error_pp(['Unexpected form in AttributeSettings::HashForm.each_element:', key, body, 'ignoring; should be caught in better parsing of settings'])
            end
          else
            attr = compose_attr(attr_prefix, key)
            value = body
            block.call(Element.new(attr, value))
          end
        end
      end

      AttrPartDelim = '/'
      def self.compose_attr(attr_prefix, attr_part)
        attr_prefix ? "#{attr_prefix}#{AttrPartDelim}#{attr_part}" : attr_part.to_s
      end

      # returns a SimpleOrderedHash object
      def self.render_in_hash_form(all_attrs_struct)
        # put assembly level attributes in ret
        ret = all_attrs_struct.assembly_attrs.sort { |a, b| a[:display_name] <=> b[:display_name] }.inject(SimpleOrderedHash.new) do |h, attr|
          h.merge(attr[:display_name] => attribute_value(attr))
        end

        ret.merge(render_in_hash_form__component_and_node_level(all_attrs_struct))
      end

      def self.render_in_hash_form__component_and_node_level(all_attrs_struct)
        ret = SimpleOrderedHash.new
        # compute attributes indexed by node (ndx_attrs)
        ndx_attrs = {} # attributes indexed by node name no asssembly wide attributes
        attrs_assembly_wide = { cmps: {} } # for attributes on assembly wide components
        all_attrs_struct.node_attrs.each do |node_attr|
          node = node_attr[:node]
          # do not display node_attributes for assembly_wide node
          unless Node.is_assembly_wide_node?(node)
            node_info = ndx_attrs[node[:display_name]] ||= { attrs: {}, cmps: {} }
            node_info[:attrs].merge!(node_attr[:display_name] => attribute_value(node_attr))
          end
        end
        all_attrs_struct.component_attrs.each do |cmp_attr|
          node = cmp_attr[:node]
          info = 
            if Node.is_assembly_wide_node?(node)
              attrs_assembly_wide
            else
              ndx_attrs[node[:display_name]] ||= { attrs: {}, cmps: {} }
            end
          cmp_print_name = cmp_attr[:nested_component].display_name_print_form()
          cmp_info = info[:cmps][cmp_print_name] ||= {}
          cmp_info.merge!(cmp_attr[:display_name] => attribute_value(cmp_attr))
        end

        # process the attributes on the asssembly wide components
        components = attrs_assembly_wide[:cmps]
        unless components.empty?
          ret['components'] = components.keys.sort.inject(SimpleOrderedHash.new) do |hash_cmp, cmp_name|
            attrs = ordered_attribute_values(components[cmp_name])
            hash_cmp.merge(component_display_key(cmp_name) => { 'attributes' => attrs })
          end
        end

        # process the attributes directly on nodes or on components on nodes
        ndx_attrs.keys.sort().each do |node_name|
          ret_node_pntr = (ret['nodes'] ||= SimpleOrderedHash.new)[node_display_key(node_name)] = SimpleOrderedHash.new

          node_info = ndx_attrs[node_name]
          ordered_node_attrs = ordered_attribute_values(node_info[:attrs])
          unless ordered_node_attrs.empty?
            ret_node_pntr['attributes'] = ordered_node_attrs 
          end

          components = node_info[:cmps]
          components.keys.sort.each do |cmp_name|
            ordered_cmp_attrs = ordered_attribute_values(components[cmp_name])
            unless ordered_cmp_attrs.empty?
              ret_cmp_pntr = (ret_node_pntr['components'] ||= SimpleOrderedHash.new)[component_display_key(cmp_name)] = SimpleOrderedHash.new
              ret_cmp_pntr['attributes'] = ordered_cmp_attrs
            end
          end
        end
        ret
      end

      def self.ordered_attribute_values(attr_vals)
        attr_vals.keys.sort.inject(SimpleOrderedHash.new) do |h, attr_name|
          h.merge(attr_name => attr_vals[attr_name])
        end
      end

      def self.component_display_key(cmp_name)
        "#{cmp_name}#{ContextDelim}"
      end

      def self.node_display_key(node_name)
        "#{node_name}#{ContextDelim}"
      end

      def self.attribute_value(attr)
        attr.convert_value_to_ruby_object()
      end
    end
  end
end; end
