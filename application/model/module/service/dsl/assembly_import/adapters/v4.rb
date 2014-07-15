module DTK; class ServiceModule
  class AssemblyImport
    r8_require('v3')
    class V4 < V3
      def self.parse_node_bindings_hash!(node_bindings_hash)      
        if hash = NodeBindings::DSL.parse_and_remove_non_legacy_hash_ref_form!(node_bindings_hash)
          DBUpdateHash.new(hash)
        end
      end
    end
  end
end; end
