module DTK
  class Assembly::Instance
    TARGET_BUILTIN_NODE_LIMIT = R8::Config[:dtk][:target][:builtin][:node_limit].to_i

    module ViolationMixin
      def find_violations
        nodes_and_cmps = get_info__flat_list(detail_level: 'components').select { |r| r[:nested_component] }
        cmps = nodes_and_cmps.map { |r| r[:nested_component] }

        unset_attr_viols = find_violations__unset_attrs()
        cmp_constraint_viols = find_violations__cmp_constraints(nodes_and_cmps, cmps.map(&:id_handle))
        cmp_parsing_errors = find_violations__cmp_parsing_error(cmps)
        unconn_req_service_refs = find_violations__unconn_req_service_refs()
        mod_refs_viols = find_violations__module_refs(cmps)
        num_of_target_nodes = find_violations__num_of_target_nodes()

        unset_attr_viols + cmp_constraint_viols + unconn_req_service_refs + mod_refs_viols + cmp_parsing_errors + num_of_target_nodes
      end

      private

      def find_violations__unset_attrs
        filter_proc = lambda { |a| a.required_unset_attribute?() }
        assembly_attr_viols = get_assembly_level_attributes(filter_proc).map { |a| Violation::ReqUnsetAttr.new(a, :assembly) }
        filter_proc = lambda { |r| r[:attribute].required_unset_attribute?() }
        component_attr_viols = get_augmented_nested_component_attributes(filter_proc).map { |a| Violation::ReqUnsetAttr.new(a, :component) }

        node_attributes = get_augmented_node_attributes(filter_proc)
        # remove attribute violations if assembly wide node
        node_attributes.delete_if do |n_attr|
          if node = n_attr[:node]
            node[:type].eql?('assembly_wide')
          end
        end
        node_attr_viols = node_attributes.map { |a| Violation::ReqUnsetAttr.new(a, :node) }

        assembly_attr_viols + component_attr_viols + node_attr_viols
      end

      def find_violations__cmp_constraints(nodes_and_cmps, cmp_idhs)
        ret = []
        return ret if cmp_idhs.empty?
        ndx_constraints = Component.get_ndx_constraints(cmp_idhs, when_evaluated: :after_cmp_added)
        # TODO: this is expensive in that it makes query for each constraint
        nodes_and_cmps.each do |r|
          if constraint_info = ndx_constraints[r[:nested_component][:id]]
            constraint_scope = { 'target_node_id_handle' => r[:node].id_handle() }
            constraint_info[:constraints].each do |constraint|
              unless constraint.evaluate_given_target(constraint_scope)
                ret << Violation::ComponentConstraint.new(constraint, r[:node])
              end
            end
          end
        end
        ret
      end

      def find_violations__unconn_req_service_refs
        ret = []
        get_augmented_ports(mark_unconnected: true).each do |aug_port|
          if aug_port[:unconnected] && aug_port[:link_def][:required]
            ret << Violation::UnconnReqServiceRef.new(aug_port)
          end
        end
        ret
      end

      def find_violations__cmp_parsing_error(cmps)
        ret = []
        return ret if cmps.empty?

        cmps.each do |cmp|
          cmp_module_branch = get_parsed_info(cmp[:module_branch_id], 'ComponentBranch')
          if cmp_module_branch && cmp_module_branch[:component_module]
            ret << Violation::ComponentParsingError.new(cmp_module_branch[:component_module][:display_name], 'Component') unless cmp_module_branch[:dsl_parsed]
          end
        end

        if service_module_branch = get_parsed_info(self[:module_branch_id], 'ServiceBranch')
          ret << Violation::ComponentParsingError.new(service_module_branch[:service_module][:display_name], 'Service') unless service_module_branch[:dsl_parsed]
        end

        # if module_branch belongs to service instance assembly_module_version? will not be nil
        assembly_branch = AssemblyModule::Service.get_assembly_branch(self)
        if assembly_branch.assembly_module_version?
          # add violation if module_branch[:dsl_parsed] == false
          ret << Violation::ComponentParsingError.new(self[:display_name], 'Service instance') unless assembly_branch[:dsl_parsed]
        end

        ret
      end

      def find_violations__module_refs(cmps)
        ret = missing = []
        multiple_ns   = {}
        return ret if cmps.empty?

        begin
          module_refs_tree = ModuleRefs::Tree.create(self, components: cmps)
        rescue ErrorUsage => e
          ret << Violation::HasItselfAsDependency.new(e.message)
          return ret
        end

        missing, multiple_ns = module_refs_tree.violations?

        unless missing.empty?
          missing.each do |k, v|
            ret << Violation::MissingIncludedModule.new(k, v)
          end
        end

        unless multiple_ns.empty?
          multiple_ns.each do |k, v|
            ret << Violation::MultipleNamespacesIncluded.new(k, v)
          end
        end

        ret
      end

      def find_violations__num_of_target_nodes
        ret = []

        target_idh = self.get_target().id_handle()
        target = target_idh.create_object(model_name: :target_instance)

        # check if allowed number of nodes is exceeded (only for builtin target)
        if target.is_builtin_target?
          new_nodes, current_nodes = [], []

          self.get_leaf_nodes().each do |l_node|
            # we need only nodes that are currently not running
            new_nodes << l_node unless l_node[:admin_op_status] == 'running'
          end

          # running target nodes
          current_nodes = target.get_target_running_nodes()
          new_nodes_size = new_nodes.size
          current_nodes_size = current_nodes.size
          ret << Violation::NodesLimitExceeded.new(new_nodes_size, current_nodes_size) if (current_nodes_size + new_nodes_size) > TARGET_BUILTIN_NODE_LIMIT
        end

        ret
      end

      def get_parsed_info(module_branch_id, type)
        ret = nil
        cols = [:id, :type, :component_id, :service_id, :dsl_parsed]

        if type.to_s.eql?('ComponentBranch')
          cols << :component_module_info
        elsif type.to_s.eql?('ServiceBranch')
          cols << :service_module
        end

        sp_hash = {
          cols: cols,
          filter: [:eq, :id, module_branch_id]
        }
        unless branch = Model.get_obj(model_handle(:module_branch), sp_hash)
          return ret
        end

        return branch if type.to_s.eql?('ComponentBranch') || type.to_s.eql?('ServiceBranch')

        if (type == 'Component')
          sp_cmp_hash = {
            cols: [:id, :display_name, :dsl_parsed],
            filter: [:eq, :id, branch[:component_id]]
          }
          Model.get_obj(model_handle(:component_module), sp_cmp_hash)
        else
          sp_cmp_hash = {
            cols: [:id, :display_name, :dsl_parsed],
            filter: [:eq, :id, branch[:service_id]]
          }
          Model.get_obj(model_handle(:service_module), sp_cmp_hash)
        end
      end
    end

    class Violation
      class ReqUnsetAttr < self
        def initialize(attr, type)
          @attr_display_name = attr.print_form(Opts.new(level: type))[:display_name]
        end

        def type
          :required_unset_attribute
        end

        def description
          "Attribute (#{@attr_display_name}) is required, but unset"
        end
      end
      class ComponentConstraint < self
        def initialize(constraint, node)
          @constraint = constraint
          @node = node
        end

        def type
          :component_constraint
        end

        def description
          "On assembly node (#{@node[:display_name]}): #{@constraint[:description]}"
        end
      end
      class UnconnReqServiceRef < self
        def initialize(aug_port)
          @augmented_port = aug_port
        end

        def type
          :unmet_dependency
        end

        def description
          "Component (#{@augmented_port.display_name_print_form()}) has an unmet dependency"
        end
      end
      class ComponentParsingError < self
        def initialize(component, type)
          @component = component
          @type = type
        end

        def type
          :parsing_error
        end

        def description
          "#{@type} '#{@component}' has syntax errors in DSL files."
        end
      end
      class MissingIncludedModule < self
        def initialize(included_module, namespace, version = nil)
          @included_module = included_module
          @namespace = namespace
          @version = version
        end

        def type
          :missing_included_module
        end

        def description
          full_name = "#{@namespace}:#{@included_module}"
          "Module '#{full_name}#{@version.nil? ? '' : '-' + @version}' is included in dsl, but not installed. Use 'print-includes' to see more details."
        end
      end
      class MultipleNamespacesIncluded < self
        def initialize(included_module, namespaces)
          @included_module = included_module
          @namespaces = namespaces
        end

        def type
          :mapped_to_multiple_namespaces
        end

        def description
          "Module '#{@included_module}' included in dsl is mapped to multiple namespaces: #{@namespaces.join(', ')}. Use 'print-includes' to see more details."
        end
      end
      class HasItselfAsDependency < self
        def initialize(message)
          @message = message
        end

        def type
          :has_itself_as_dependency
        end

        def description
          @message
        end
      end

      class NodesLimitExceeded < self
        def initialize(new_nodes, running)
          @new = new_nodes
          @running = running
        end

        def type
          :nodes_limit_exceeded
        end

        def description
          "There are #{@running} nodes currently running in builtin target. Unable to create #{@new} new nodes beacuse it will exceed number of nodes allowed in builtin target (#{TARGET_BUILTIN_NODE_LIMIT})"
        end
      end
    end
  end
end
