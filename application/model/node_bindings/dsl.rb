module DTK
  class NodeBindings
    class DSL
      def self.parse_and_remove_non_legacy!(node_bindings_hash)
       parse_input_hash = Hash.new
        node_bindings_hash.each_pair do |node,node_target|
          unless node_target.kind_of?(String) and not node_target =~ /\//
            parse_input_hash[node] = node_bindings_hash.delete(node)
          end
        end
        parse_and_reify(parse_input_hash)
      end

      def self.parse_and_reify(parse_input_hash) 
        Content.parse_and_reify(ParseInput.new(parse_input_hash))
      end
    end
  end
end
