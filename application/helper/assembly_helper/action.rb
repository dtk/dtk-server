module Ramaze::Helper
  module AssemblyHelper
    ##
    # helpers related to assembly command and control actions
    module ActionMixin
      # creates a queue object, initiates action that will push results on queue
      # if any errors, it wil just push error conditions on queue
      def initiate_action(action_module, assembly, params, node_pattern)
        queue = ::DTK::ActionResultsQueue.new
        begin
          nodes = ret_matching_nodes(assembly, node_pattern)
          queue.initiate(nodes,action_module.action_hash(),params)
        rescue ::DTK::ErrorUsage => e
          queue.push(:error,e.message)
        end
        queue
      end
      
      def ret_matching_nodes(assembly, node_pattern)
        #TODO: can handle more efficiently than getting all nodes and filtering
        nodes = assembly.get_leaf_nodes()
        if node_pattern.nil? or node_pattern.empty?
          nodes
        else
          ret = nil
          if node_pattern.kind_of?(Hash) and node_pattern.size == 1
            case node_pattern.keys.first
            when :node_name
              node_name = node_pattern.values.first
              ret = nodes.select{|n|n.assembly_node_print_form() == node_name}
              if ret.empty?
                raise ::DTK::ErrorUsage.new("No node matches name (#{node_name})")
              end
            when :node_id
              node_id = node_pattern.values.first
              ret = nodes.select{|n|n.id == node_id}
              if ret.empty?
                raise ::DTK::ErrorUsage.new("No node matches id (#{node_id})")
              end
            end
          end
          ret || raise(::DTK::ErrorUsage.new("Unexpected form of node_pattern"))
        end
      end
      private :ret_matching_nodes
      
      # TODO: refactor below in terms of above
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
      def nodes_valid_for_stop_or_start?(assembly, node_pattern, status_pattern)
        nodes = assembly.get_leaf_nodes()
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
          if node.get_field?(:type) == ::DTK::Node::Type::Node.staged
            assembly_name = ::DTK::Assembly::Instance.pretty_print_name(assembly)
            return nodes, false, "Nodes for assembly '#{assembly_name}' are 'staged' and as such cannot be started/stopped."
          end
        end
        
        # check for status -> this will translate to /running|pending/ and /stopped|pending/ checks
        filtered_nodes = nodes.select { |node| node.get_field?(:admin_op_status) =~ Regexp.new("#{status_pattern.to_s}|pending") }
        if filtered_nodes.size == 0
          assembly_name = ::DTK::Assembly::Instance.pretty_print_name(assembly)
        return nodes, false, "There are no #{status_pattern} nodes for assembly '#{assembly_name}'."
        end
        
        return filtered_nodes, true, nil      
      end
      #TODO: collapse above and below
      def nodes_are_up?(assembly_name, nodes, status_pattern)
        # check if staged
        nodes.each do |node|
          if node.get_field?(:type) == ::DTK::Node::Type::Node.staged
            return nodes, false, "Serverspec tests cannot be executed on nodes that are 'staged'."
          end
        end
        
        # check for status -> this will translate to /running|pending/ and /stopped|pending/ checks
        filtered_nodes = nodes.select { |node| node.get_field?(:admin_op_status) =~ Regexp.new("#{status_pattern.to_s}|pending") }
        if filtered_nodes.size == 0
          return nodes, false, "There are no #{status_pattern} nodes for assembly '#{assembly_name}'."
        end
        
        [filtered_nodes, true, nil]
      end
    end
  end
end
