module DTK; class Attribute
  class Pattern; class Type
    class ComponentLevel < self
      include CommonNodeComponentLevel

      def create_attribute_on_template(cmp_template,opts={})
        new_attr = create_attributes([cmp_template]).first
        if update_dsl = opts[:update_dsl]
          unless module_branch = update_dsl[:module_branch]
            raise Error.new("If update_dsl is specified then module_branch must be provided")
          end
          module_branch.incrementally_update_component_dsl([new_attr],component_template: cmp_template)
        end
        new_attr.id_handle()
      end

      def type
        :component_level
      end

      def match_attribute_mapping_endpoint?(am_endpoint)
        am_endpoint[:type] == 'component_attribute' &&
          am_endpoint[:component_type] == component_instance()[:component_type] &&
          am_endpoint[:attribute_name] == attribute_name()
      end
      
      def am_serialized_form
        "#{component_instance()[:component_type]}.#{attribute_name()}"
      end
      
      def set_parent_and_attributes!(parent_idh,opts={})
        ret = self
        @attribute_stacks = []
        ndx_nodes  = ret_matching_nodes(parent_idh).inject({}){|h,r|h.merge(r[:id] => r)}
        if ndx_nodes.empty?
          if create_this_type?(opts)
            raise ErrorUsage.new("Node name (#{pattern_node_name()}) in attribute does not match an existing node")
          end
          return ret 
        end

        cmp_fragment = pattern_component_fragment()
        ndx_cmps = ret_matching_components(ndx_nodes.values,cmp_fragment).inject({}){|h,r|h.merge(r[:id] => r)}
        if ndx_cmps.empty?
          if create_this_type?(opts)
            raise ErrorUsage.new("Component name (#{pattern_component_name()}) in attribute does not match an existing component in node (#{pattern_node_name()})")
          end
          return ret 
        end
        
        attr_fragment = pattern_attribute_fragment()
        attrs = ret_matching_attributes(:component,ndx_cmps.values.map{|r|r.id_handle()},attr_fragment)
        if attrs.empty? && create_this_type?(opts)
          @created = true
          set_attribute_properties!(opts[:attribute_properties]||{})
          attrs = create_attributes(ndx_cmps.values)
        end
        @attribute_stacks = attrs.map do |attr|
          cmp = ndx_cmps[attr[:component_component_id]]
          # TODO: this shoudl be done more internally
          fill_in_external_ref?(attr,cmp)
          {
            attribute: attr,
            component: cmp,
            node: ndx_nodes[cmp[:node_node_id]]
          }
        end 
        ret
      end

      private

      def fill_in_external_ref?(attr,component)
        unless attr.get_field?(:external_ref)
          component_type = component.get_field?(:component_type)
          attr_name = attr.get_field?(:display_name)
          external_ref = attr[:external_ref] = {
            # TODO: hard coded and not centralized logic
            type: 'puppet_attribute',
            path: "node[#{component_type}][#{attr_name}]"
          }
          attr.update({external_ref: external_ref},convert: true)
        end
        attr
      end

      def pattern_node_name
        Pattern.node_name(pattern())
      end

      def pattern_component_fragment
        Pattern.component_fragment(pattern())
      end

      def pattern_attribute_fragment
        Pattern.attribute_fragment(pattern())
      end

      def pattern_component_name
        first_name_in_fragment(pattern_component_fragment())
      end
    end
  end; end
end; end

