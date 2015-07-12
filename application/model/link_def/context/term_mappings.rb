module DTK
  class LinkDef::Context
    class TermMappings < Hash
      def self.create_and_update_cmp_attr_index(node_mappings, component_attr_index, attribute_mappings, cmp_mappings)
        ret = TermMappings.new()
        ret.update_this_and_cmp_attr_index(node_mappings, component_attr_index, attribute_mappings, cmp_mappings)
      end
      def update_this_and_cmp_attr_index(node_mappings, component_attr_index, attribute_mappings, cmp_mappings)
        add_component_refs!(cmp_mappings)
        add_attribute_refs!(node_mappings, component_attr_index, attribute_mappings)
        self
      end

      def set_components!(link, cmp_mappings)
        values.each do |v|
          v.set_component_remote_and_local_value!(link, cmp_mappings)
        end
      end

      def set_attribute_values!(_link, _link_defs_info, node_mappings)
        attrs_to_set = component_attributes_to_set()
        get_and_update_component_attributes!(attrs_to_set)

        attrs_to_set = node_attributes_to_set(node_mappings)
        get_and_update_node_attributes!(attrs_to_set)
      end

      def find_attribute_object?(term_index)
        self[term_index]
      end

      def get_and_update_component_attributes!(attrs_to_set)
        return if attrs_to_set.empty?
        from_db = Component.get_virtual_attributes__include_mixins(attrs_to_set, attribute_fields_to_get())
        attrs_to_set.each do |component_id, hash_val|
          next unless cmp_info = from_db[component_id]
          hash_val[:attribute_info].each do |a|
            attr_name = a[:attribute_name]
            a[:value_object].set_attribute_value!(cmp_info[attr_name]) if cmp_info.key?(attr_name)
          end
        end
      end

      def get_and_update_node_attributes!(attrs_to_set)
        return if attrs_to_set.empty?
        from_db = Node.get_virtual_attributes(attrs_to_set, attribute_fields_to_get())
        attrs_to_set.each do |node_id, hash_val|
          next unless node_info = from_db[node_id]
          hash_val[:attribute_info].each do |a|
            attr_name = a[:attribute_name]
            a[:value_object].set_attribute_value!(node_info[attr_name]) if node_info.key?(attr_name)
          end
        end
      end

      private

      def add_component_refs!(cmp_mappings)
        cmp_mappings.each_value { |cmp| add_component_ref!(cmp) }
      end

      def add_attribute_refs!(node_mappings, component_attr_index, attribute_mappings)
        attribute_mappings.each do |am|
          add_ref!(node_mappings, component_attr_index, am[:input])
          add_ref!(node_mappings, component_attr_index, am[:output])
        end
      end

      def add_component_ref!(component)
        component_type = component[:component_type]
        term_index = component_type
        self[term_index] ||= Value::Component.new(component_type: component_type)
      end

      def attribute_fields_to_get
        # TODO: prune which of these data type attributes needed; longer term is to clean them up to be normalized
        [:id, :value_derived, :value_asserted, :data_type, :semantic_data_type, :semantic_type, :semantic_type_summary]
      end

      def component_attributes_to_set
        ret = {}
        each_value do |v|
          if v.is_a?(Value::ComponentAttribute)
            # v.component can be null if refers to component created by an event
            next unless cmp = v.component
            a = (ret[cmp[:id]] ||= { component: cmp, attribute_info: [] })[:attribute_info]
            a << { attribute_name: v.attribute_ref.to_s, value_object: v }
          end
        end
        ret
      end

      def node_attributes_to_set(node_mappings)
      ret = {}
        each_value do |v|
          if v.is_a?(Value::NodeAttribute)
            unless node = node_mappings[v.node_ref.to_sym]
              Log.error('cannot find node associated with node ref')
              next
            end
            a = (ret[node[:id]] ||= { node: node, attribute_info: [] })[:attribute_info]
            a << { attribute_name: v.attribute_ref.to_s, value_object: v }
          end
        end
        ret
      end

      def add_ref!(node_mappings, component_attr_index, term)
        # TODO: see if there can be name conflicts between different types in which nmay want to prefix with
        # type (type's initials, like CA for componanet attribute)
        term_index = term[:term_index]
        value = self[term_index] ||= Value.create(term, node_mappings: node_mappings)
        value.update_component_attr_index!(component_attr_index)
      end
    end
  end
end
