module DTK; class ServiceModule
  class AssemblyImport
    r8_require('v3')
    class V4 < V3
      def self.parse_node_bindings_hash!(node_bindings_hash)      
        pp [:node_bindings_hash, node_bindings_hash]
#        #TODO: stub: remove new form and call NodeBindings::DSL.parse(..)
      end
    end
  end
end; end
