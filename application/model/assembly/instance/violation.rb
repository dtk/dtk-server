module DTK
  class Assembly::Instance
    module ViolationMixin
      def find_violations()
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
          cmp_module_branch = get_parsed_info(cmp[:module_branch_id], "ComponentBranch")
          if cmp_module_branch && cmp_module_branch[:component_module]
            ret << Violation::ComponentParsingError.new(cmp_module_branch[:component_module][:display_name], "Component") unless cmp_module_branch[:dsl_parsed]
          end
        end

        if service_module_branch = get_parsed_info(self[:module_branch_id], "ServiceBranch")
          ret << Violation::ComponentParsingError.new(service_module_branch[:service_module][:display_name], "Service") unless service_module_branch[:dsl_parsed]
        end

        # if module_branch belongs to service instance assembly_module_version? will not be nil
        assembly_branch = AssemblyModule::Service.get_assembly_branch(self)
        if assembly_branch.assembly_module_version?
          # add violation if module_branch[:dsl_parsed] == false
          ret << Violation::ComponentParsingError.new(self[:display_name], "Service instance") unless assembly_branch[:dsl_parsed]
        end

        ret
      end

      def find_violations__module_refs(cmps)
        ret = missing = Array.new
        multiple_ns   = Hash.new
        return ret if cmps.empty?

        assembly_branch      = AssemblyModule::Service.get_assembly_branch(self)
        module_refs_tree     = ModuleRefs::Tree.create(self,assembly_branch,cmps)
        missing, multiple_ns = module_refs_tree.violations?

        unless missing.empty?
          missing.each do |miss|
            ret << Violation::MissingIncludedModule.new(miss)
          end
        end

        unless multiple_ns.empty?
          multiple_ns.each do |k,v|
            ret << Violation::MultipleNamespacesIncluded.new(k,v)
          end
        end

        ret
      end

      def get_parsed_info(module_branch_id, type)
        ret = nil
        cols = [:id, :type, :component_id, :service_id, :dsl_parsed]

        if type.to_s.eql?("ComponentBranch")
          cols << :component_module_info
        elsif type.to_s.eql?("ServiceBranch")
          cols << :service_module
        end

        sp_hash = {
          :cols => cols,
          :filter => [:eq, :id, module_branch_id]
        }
        unless branch = Model.get_obj(model_handle(:module_branch),sp_hash)
          return ret
        end

        return branch if type.to_s.eql?("ComponentBranch") || type.to_s.eql?("ServiceBranch")

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
        def initialize(included_module, version = nil)
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
      class MultipleNamespacesIncluded < self
        def initialize(included_module, namespaces)
          @included_module = included_module
          @namespaces = namespaces
        end
        def type()
          :mapped_to_multiple_namespaces
        end
        def description()
          "Module '#{@included_module}' included in dsl is mapped to multiple namespaces: #{@namespaces.join(', ')}."
        end
      end
    end
  end
end
