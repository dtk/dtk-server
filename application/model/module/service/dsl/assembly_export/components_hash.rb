module DTK; class ServiceModule
  class AssemblyExport
    class ComponentsHash < Hash
      attr_reader :nodes

      def initialize(nodes = {})
        super()
        @nodes = nodes
      end

      def order_components_hash(hash_nodes)
        hash_nodes.each do |node_name, node_content|
          if node_components = @nodes.key?(node_name) && node_content[:components]
            parse_components(node_components, @nodes[node_name])
          end
        end
      end

      private

      def parse_components(components, existing_node_content)
        require 'debugger'
        Debugger.wait_connection = true
        Debugger.start_remote
        debugger
        b = []
        if node_cmps = !components.empty? && existing_node_content['components']
          a = nil
          node_cmps.each do |node_cmp|
            if cmp_name = node_cmp.is_a?(Hash) && node_cmp.keys.first
              a = components.find{ |c| c.is_a?(Hash) ? (c.keys.first.eql?(cmp_name)) : (c.eql?(cmp_name)) }
            end
            ap "-----------------------------"
            ap a
            ap node_cmp
            ap "-----------------------------"
            b << components.delete(a||node_cmp)
          end
          require 'debugger'
          Debugger.wait_connection = true
          Debugger.start_remote
          debugger
          ap "COMPONENTS :::::::::::::::::::::"
          ap components
        end
      end
    end
  end
end; end