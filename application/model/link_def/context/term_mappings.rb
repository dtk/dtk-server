module DTK
  class LinkDefContext
    class TermMappings < Hash
      def find_attribute(term_index)
        match = self[term_index]
        match && match.value
      end

      def find_component(term_index)
        match = self[term_index]
        match && match.value
      end

      def add_attribute_refs!(component_attr_index,attribute_mappings)
        attribute_mappings.each do |am|
          add_ref!(component_attr_index,am[:input])
          add_ref!(component_attr_index,am[:output])
        end
      end

      def add_ref_component!(component_type)
        term_index = component_type
        self[term_index] ||= Value::Component.new(:component_type => component_type)
      end

      def set_components!(link,cmp_mappings)
        values.each do |v|
          v.set_component_remote_and_local_value!(link,cmp_mappings)
        end
      end

      def component_attributes_to_set()
        ret = Hash.new
        each_value do |v|
          if v.kind_of?(Value::ComponentAttribute)
          # v.component can be null if refers to component created by an event
            next unless cmp = v.component
            a = (ret[cmp[:id]] ||= {:component => cmp, :attribute_info => Array.new})[:attribute_info]
            a << {:attribute_name => v.attribute_ref.to_s, :value_object => v}
          end
        end
        ret
      end

      def node_attributes_to_set(node_mappings)
        ret = Hash.new
        each_value do |v|
          if v.kind_of?(Value::NodeAttribute)
            unless node = node_mappings[v.node_ref.to_sym]
              Log.error("cannot find node associated with node ref")
              next
            end
            if node.is_node_group?()
              # TODO: put in logic to treat this case by getting attributes on node members and doing fan in mapping
              # to input (which wil be restricted to by a non node group)
              raise ErrorUsage.new("Not treating link from a node attribute (#{v.attribute_ref}) on a node group (#{node[:display_name]})")
            end
            a = (ret[node[:id]] ||= {:node => node, :attribute_info => Array.new})[:attribute_info]
            a << {:attribute_name => v.attribute_ref.to_s, :value_object => v}
          end
        end
        ret
      end

     private
      def add_ref!(component_attr_index,term)
        # TODO: see if there can be name conflicts between different types in which nmay want to prefix with 
        # type (type's initials, like CA for componanet attribute)
        term_index = term[:term_index]
        value = self[term_index] ||= Value.create(term)
        value.update_component_attr_index!(component_attr_index)
      end

    end
  end
end
