module DTK
  class NodeBindings
    class Content < Hash
      def has_node_target?(node)
        self[node.get_field?(:display_name)]
      end

      def hash_form()
        inject(Hash.new) do |h,(node_name,node_target)|
          h.merge(node_name => node_target.hash_form())
        end
      end
      
      def self.parse_and_reify(parse_input)
        unless parse_input.type?(Hash)
          raise parse_input.error("Node Bindings section has an illegal form: ?input")
        end

        if parse_input.input.empty?
          return nil 
        end

        #TODO: check each node belongs to assembly
        parse_input.input.inject(new()) do |h,(node,node_target)|
          h.merge(node => NodeTarget.parse_and_reify(parse_input.child(node_target)))
        end
      end
    end
  end
end
