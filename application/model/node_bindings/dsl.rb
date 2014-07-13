module DTK
  class NodeBindings
    class DSL
      r8_nested_require('dsl','parse_input')
      r8_nested_require('dsl','generate')
      def self.parse_and_remove_non_legacy!(node_bindings_hash)
       parse_input_hash = Hash.new
        node_bindings_hash.each_pair do |node,node_target|
          unless node_target.kind_of?(String) and not node_target =~ /\//
            parse_input_hash[node] = node_bindings_hash.delete(node)
          end
        end
        parse(parse_input_hash)
      end

      def self.parse(parse_input_hash) 
        NodeBindings.parse(ParseInput.new(parse_input_hash))
      end
    end
  end
end
