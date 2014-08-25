module DTK
  class NodeBindings
    class Content < Hash
      def has_node_target?(assembly_node_name)
        self[assembly_node_name.to_sym]
      end

      def set_node_bindings(target)
        each_pair do |node_name,node_target|
          target_specific_info = node_target.find_target_specific_info(target)
          # TODO: process this info
        end
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
