module DTK; class ServiceModule
  class AssemblyImport
    r8_require('v3')
    class V4 < V3
      def self.parse_node_bindings_hash!(node_bindings_hash)      
        NodeBindings::DSL.parse_and_remove_non_legacy!(node_bindings_hash)
      end
    end
  end
end; end
