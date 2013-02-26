module DTK
  class Assembly::Instance
    module ViolationMixin
      def find_violations()
        unset_attr_viols = find_violations__unset_attrs()
        cmp_constraint_viols = find_violations__cmp_constraints()
        unconn_req_service_refs = find_violations__unconn_req_service_refs()
        unset_attr_viols + cmp_constraint_viols + unconn_req_service_refs
      end
     private
      def find_violations__unset_attrs()
        filter_proc = lambda{|r|r[:attribute].required_unset_attribute?()}
        assembly_attr_viols = get_assembly_level_attributes(filter_proc).map{|a|Violation::ReqUnsetAttr.new(a,:assembly)}
        component_attr_viols = get_augmented_nested_component_attributes(filter_proc).map{|a|Violation::ReqUnsetAttr.new(a,:component)}
        node_attr_viols = get_augmented_node_attributes(filter_proc).map{|a|Violation::ReqUnsetAttr.new(a,:node)}
        assembly_attr_viols + component_attr_viols + node_attr_viols
      end

      def find_violations__cmp_constraints()
        ret = Array.new
        nodes_and_cmps = get_info__flat_list(:detail_level => "components").select{|r|r[:nested_component]}
        cmp_idhs = nodes_and_cmps.map{|r|r[:nested_component].id_handle()}
        ndx_constraints = Component.get_ndx_constraints(cmp_idhs,:when_evaluated => :after_cmp_added)
        #TODO: this is expensive in that it makes query for each constraint
        nodes_and_cmps.each do |r|
          if constraint_info = ndx_constraints[r[:nested_component][:id]]
            constraint_scope = {"target_node_id_handle" => r[:node].id_handle()}
            constraint_info[:constraints].each do |constraint|
              unless constraint.evaluate_given_target(constraint_scope)
                ret << Violation::ComponentConstraint.new(constraint,r[:node])
              end
            end
          end
        end
        ret
      end

      def find_violations__unconn_req_service_refs()
        ret = Array.new
        get_augmented_ports(:mark_unconnected=>true).each do |aug_port|
          if aug_port[:unconnected] and aug_port[:link_def][:required]
            ret << Violation::UnconnReqServiceRef.new(aug_port)
          end
        end
        ret
      end

    end

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
        def initialize(constraint,node)
          @constraint = constraint
          @node = node
        end
        def type()
          :component_constraint
        end
        def description()
          "On assembly node (#{@node[:display_name]}): #{@constraint[:description]}"
        end
      end
      class UnconnReqServiceRef < self
        def initialize(aug_port)
          @augmented_port = aug_port
        end
        def type()
          :unconnected_service_ref
        end
        def description()
          "Service ref (#{@augmented_port.display_name_print_form()}) is not connected, but required to be"
        end
      end
    end
  end
end
