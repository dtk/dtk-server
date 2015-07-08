module DTK; class  Assembly; class Instance
  module OpStatus
    module ClassMixin
      # returns
      #   'running' - if at least one node is running
      #   'stopped' - if there is atleast one node stopped and no nodes running
      #   'pending' - if all nodes are pending or no nodes
      #    nil - if cant tell
      def op_status(assembly_nodes)
        return 'pending' if assembly_nodes.empty?
        stop_found = false
        assembly_nodes.each do |node|
          case node[:admin_op_status]
          when 'running'
            return 'running'
          when 'stopped'
            stop_found = true
          when 'pending'
            # no op
          else
            return nil
          end
        end
        stop_found ? 'stopped' : 'pending'
      end

      def op_status_all_pending?(assembly_nodes)
        assembly_nodes.find do |node|
          status = node[:admin_op_status]
          status.nil? || status != 'pending'
        end.nil?
      end
    end

    module Mixin
      def any_stopped_nodes?
        !!get_leaf_nodes(cols: [:id,:admin_op_status]).find{|node|node[:admin_op_status] == 'stopped'}
      end

      # TODO: check that nelow correctly dont use get_leaf_nodes
      def op_status
        assembly_nodes = get_nodes(:admin_op_status)
        self.class.op_status(assembly_nodes)
      end

      def op_status_all_pending?
        assembly_nodes = get_nodes(:admin_op_status)
        self.class.op_status_all_pending?(assembly_nodes)
      end
      ###########

      ##
      # Method that will validate if nodes list is ready to started or stopped.
      #
      # * *Args*    :
      #   - +assembly_id+     ->  assembly id
      #   - +node_or_ngs+     ->  array containig node or node group elements
      #   - +node_pattern+    ->  match id regexp pattern
      #   - +status_pattern+  ->  pattern to match node status
      # * *Returns* :
      #   - is valid flag
      #   - filtered nodes by pattern (if pattern not nil)
      #   - error message in case it is not valid
      #
      def nodes_valid_for_stop_or_start(node_pattern, status_pattern)
        nodes = get_leaf_nodes()

        # do not start/stop assembly wide nodes
        nodes.delete_if{|n| n[:type].eql?('assembly_wide')}

        # check for pattern
        unless node_pattern.nil? || node_pattern.empty?
          regex = Regexp.new(node_pattern)

          # temp nodes_list
          nodes_list = nodes

          nodes = nodes.select { |node| regex =~ node.id.to_s}
          if nodes.size == 0
            nodes = nodes_list.select { |node| node_pattern.to_s.eql?(node.display_name.to_s)}
            return nodes, false, "No nodes have been matched via ID ~ '#{node_pattern}'." if nodes.size == 0
          end
        end
        # check if staged
        nodes.each do |node|
          if node.get_field?(:type) == Node::Type::Node.staged
            assembly_name = pretty_print_name()
            return nodes, false, "Nodes for assembly '#{assembly_name}' are 'staged' and as such cannot be started/stopped."
          end
        end

        # check for status -> this will translate to /running|pending/ and /stopped|pending/ checks
        filtered_nodes = nodes.select { |node| node.get_field?(:admin_op_status) =~ Regexp.new("#{status_pattern}|pending") }
        if filtered_nodes.size == 0
          assembly_name = pretty_print_name()
        return nodes, false, "There are no #{status_pattern} nodes for assembly '#{assembly_name}'."
        end

        return filtered_nodes, true, nil
      end

      # TODO: collapse above and below
      def nodes_are_up?(nodes, status_pattern, opts={})
        what = opts[:what]||"Command"
        # check if staged
        nodes.each do |node|
          if node.get_field?(:type) == Node::Type::Node.staged
            return nodes, false, "#{what} cannot be executed on nodes that are 'staged'."
          end
        end

        # check for status -> this will translate to /running|pending/ and /stopped|pending/ checks
        filtered_nodes = nodes.select { |node| node.get_field?(:admin_op_status) =~ Regexp.new("#{status_pattern}|pending") }
        if filtered_nodes.size == 0
          assembly_name = pretty_print_name()
          return nodes, false, "There are no #{status_pattern} nodes for assembly '#{pretty_print_name(assembly_name)}'."
        end

        [filtered_nodes, true, nil]
      end
    end
  end
end; end; end


