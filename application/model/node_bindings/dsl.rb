module DTK
  class NodeBindings
    class DSL < self
<<<<<<< HEAD
      def self.create_from_hash(assembly,parse_input_hash)
        parsed_content = parse_content?(parse_input_hash)
        create_stub(assembly.model_handle(:node_bindings),:content => parsed_content)
      end

      def self.parse!(node_bindings_hash,opts={})
        return nil unless node_bindings_hash
        delete_els = opts[:remove_non_legacy]
=======
      def self.parse_and_remove_non_legacy_hash_ref_form!(node_bindings_hash)
        return nil unless node_bindings_hash
>>>>>>> namespace_support_merged
        parse_input_hash = Hash.new
        node_bindings_hash.each_pair do |node,node_target|
          unless node_target.kind_of?(String) and not node_target =~ /\//
            parse_input_hash[node] = (delete_els ? node_bindings_hash.delete(node) : node_target)
          end
        end
        if content = parse_content?(parse_input_hash)
          {node_bindings_ref(content) => {:content => content.hash_form()}}
        end
      end

     private
      def self.parse_content?(parse_input_hash)
        Content.parse_and_reify(ParseInput.new(parse_input_hash))
      end
    end
  end
end
