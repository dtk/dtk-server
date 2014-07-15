module DTK
  class NodeBindings
    class DSL < self
      def self.parse_and_remove_non_legacy_hash_ref_form!(node_bindings_hash)
       parse_input_hash = Hash.new
        node_bindings_hash.each_pair do |node,node_target|
          unless node_target.kind_of?(String) and not node_target =~ /\//
            parse_input_hash[node] = node_bindings_hash.delete(node)
          end
        end
        if content = Content.parse_and_reify(ParseInput.new(parse_input_hash))
          {node_bindings_ref(content) => {:content => content.hash_form()}}
        end
      end
    end
  end
end
