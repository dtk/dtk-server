module DTK; class ServiceModule
  class AssemblyImport
    r8_require('v3')
    class V4 < V3
      def self.parse_node_bindings_hash!(node_bindings_hash,opts={})      
        if hash = NodeBindings::DSL.parse!(node_bindings_hash,opts)
          DBUpdateHash.new(hash)
        end
      end
    end
  end
end; end
