module DTK
  class NodeBindings
    class DSL < self
      def self.parse!(node_bindings_hash,opts={})
        return nil unless node_bindings_hash
        delete_els = opts[:remove_non_legacy]
        parse_input_hash = Hash.new
        node_bindings_hash.each_pair do |node,node_target|
          unless node_target.kind_of?(String) and not node_target =~ /\//
            parse_input_hash[node] = (delete_els ? node_bindings_hash.delete(node) : node_target)
          end
        end
        if content = Content.parse_and_reify(ParseInput.new(parse_input_hash))
          {node_bindings_ref(content) => {:content => content.hash_form()}}
        end
      end
    end
  end
end
