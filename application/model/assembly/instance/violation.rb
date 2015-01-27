module DTK
  class Assembly::Instance
    module ViolationMixin
      def find_violations()
        update_obj!(:module_branch_id)
        nodes_and_cmps = get_info__flat_list(:detail_level => "components").select{|r|r[:nested_component]}
        cmps = nodes_and_cmps.map{|r|r[:nested_component]}

        unset_attr_viols = find_violations__unset_attrs()
        cmp_constraint_viols = find_violations__cmp_constraints(nodes_and_cmps,cmps.map{|cmp|cmp.id_handle()})
        cmp_parsing_errors = find_violations__cmp_parsing_error(cmps)
        unconn_req_service_refs = find_violations__unconn_req_service_refs()
        mod_refs_viols = find_violations__module_refs(cmps)

        unset_attr_viols + cmp_constraint_viols + unconn_req_service_refs + mod_refs_viols + cmp_parsing_errors
      end
     private
      def find_violations__unset_attrs()
        filter_proc = lambda{|a|a.required_unset_attribute?()}
        assembly_attr_viols = get_assembly_level_attributes(filter_proc).map{|a|Violation::ReqUnsetAttr.new(a,:assembly)}
        filter_proc = lambda{|r|r[:attribute].required_unset_attribute?()}
        component_attr_viols = get_augmented_nested_component_attributes(filter_proc).map{|a|Violation::ReqUnsetAttr.new(a,:component)}
        node_attr_viols = get_augmented_node_attributes(filter_proc).map{|a|Violation::ReqUnsetAttr.new(a,:node)}
        assembly_attr_viols + component_attr_viols + node_attr_viols
      end

      def find_violations__cmp_constraints(nodes_and_cmps,cmp_idhs)
        ret = Array.new
        return ret if cmp_idhs.empty?
        ndx_constraints = Component.get_ndx_constraints(cmp_idhs,:when_evaluated => :after_cmp_added)
        # TODO: this is expensive in that it makes query for each constraint
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

      def find_violations__cmp_parsing_error(cmps)
        ret = Array.new
        return ret if cmps.empty?

        cmps.each do |cmp|
          cmp_module = get_parsed_info(cmp[:module_branch_id], "Component")
          if cmp_module
            ret << Violation::ComponentParsingError.new(cmp_module[:display_name], "Component") unless cmp_module[:dsl_parsed]
          end
        end

        assembly_branch_id = self[:module_branch_id]
        if service_module = get_parsed_info(assembly_branch_id, "Service")
          ret << Violation::ComponentParsingError.new(service_module[:display_name], "Service") unless service_module[:dsl_parsed]
        end
        ret
      end

      # this also serves to set implementation_id on module includes that are not set already
      # TODO: seperelate check versuses setting implementation_id 
      def find_violations__module_refs(cmps)
        ret = Array.new
        return ret if cmps.empty?
        cmp_idhs = cmps.map{|cmp|cmp.id_handle()}
        if included_modules = Component::IncludeModule.find_violations_and_set_impl(cmp_idhs)
          included_modules.each do |incl_mod|
            ret << Violation::MissingIncludedModule.new(incl_mod[:module_name], incl_mod[:version])
          end 
        end
# For Aldin:
# TODO: replace above by using teh following to compute _module_refs violations
#        module_refs_tree = ModuleRefs::Tree.create(self,cmps)
#      ... module_refs_tree.violations? ...
# That is compute module_refs_tree and call violations? (which you wil need to write; it is stubbed now to return nil
# module_refs_tree.violations? shoudl return info that if non nill can be used to add module_refs violations to ret
# theer are two types: i) module names taht are missing refs and ii) case where module name maps to multiple namespaces
        ret
      end

      def get_parsed_info(module_branch_id, type)
        ret = nil
        sp_hash = {
          :cols => [:id, :type, :component_id, :service_id],
          :filter => [:eq, :id, module_branch_id]
        }
        unless branch = Model.get_obj(model_handle(:module_branch),sp_hash)
        # assembly, such as workspace does not have a branch associated with it
          return ret
        end

        if (type == "Component")
          sp_cmp_hash = {
            :cols => [:id, :display_name, :dsl_parsed],
            :filter => [:eq, :id, branch[:component_id]]
          }
          Model.get_obj(model_handle(:component_module),sp_cmp_hash)
        else
          sp_cmp_hash = {
            :cols => [:id, :display_name, :dsl_parsed],
            :filter => [:eq, :id, branch[:service_id]]
          }
          Model.get_obj(model_handle(:service_module),sp_cmp_hash)
        end
      end

    end

    class Violation 
      class ReqUnsetAttr < self
        def initialize(attr,type)
          @attr_display_name = attr.print_form(Opts.new(:level=>type))[:display_name]
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
          :unmet_dependency
        end
        def description()
          "Component (#{@augmented_port.display_name_print_form()}) has an unmet dependency"
        end
      end
      class ComponentParsingError < self
        def initialize(component, type)
          @component = component
          @type = type
        end
        def type()
          :parsing_error
        end
        def description()
          "#{@type} '#{@component}' has syntax errors in DSL files."
        end
      end
      class MissingIncludedModule < self
        def initialize(included_module, version)
          @included_module = included_module
          @version = version
        end
        def type()
          :missing_included_module
        end
        def description()
          "Module '#{@included_module}#{@version.nil? ? '' : '-'+@version}' is included in dsl, but not installed."
        end
      end
    end
  end
end
