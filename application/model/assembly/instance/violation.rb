module DTK
  class Assembly::Instance
    class Violation 
      class ReqUnsetAttr < self
        def initialize(attr,type)
          @attr_display_name = Attribute::Pattern::Display.new(attr,type).print_form()[:display_name]
        end
        def type()
          :required_unset_attribute
        end
        def description()
          "Attribute (#{@attr_display_name}) is required, but unset"
        end
      end
      class ComponentConstraint < self
      end
      class DanglingServiceRef < self
      end
    end
    module ViolationMixin
      def find_violations()
        unset_attr_viols = find_violations__unset_attrs()
        unless unset_attr_viols.empty?()
          pp unset_attr_viols.map{|v|{:type => v.type(), :description => v.description()}} 
          raise ErrorUsage.new("unset vars")
        end
      end
     private
      def find_violations__unset_attrs()
        filter_proc = lambda{|a|a.required_unset_attribute?()}
        assembly_attr_viols = get_assembly_level_attributes(filter_proc).map{|a|Violation::ReqUnsetAttr.new(a,:assembly)}
        component_attr_viols = get_augmented_nested_component_attributes(filter_proc).map{|a|Violation::ReqUnsetAttr.new(a,:component)}
        node_attr_viols = get_augmented_node_attributes(filter_proc).map{|a|Violation::ReqUnsetAttr.new(a,:node)}
        assembly_attr_viols + component_attr_viols + node_attr_viols
      end

    end
  end
end
