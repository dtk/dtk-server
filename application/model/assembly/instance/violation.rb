module DTK
  class Assembly::Instance
    module ViolationMixin
      def find_violations()
        unset_attrs = find_violations__unset_attrs()
        unless unset_attrs.empty?()
          pp unset_attrs
          raise ErrorUsage.new("unset vars")
        end
      end
     private
      def find_violations__unset_attrs()
        filter_proc = lambda{|a|a.required_unset_attribute?()}
        assembly_attrs = get_assembly_level_attributes(filter_proc)
        component_attrs = get_augmented_nested_component_attributes(filter_proc)
        node_attrs = get_augmented_node_attributes(filter_proc)
        assembly_attrs + component_attrs + node_attrs
      end

    end
  end
end
