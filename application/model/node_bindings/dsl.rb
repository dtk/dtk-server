module DTK
  class NodeBindings
    class DSL
      r8_nested_require('dsl','parsing_error')
      r8_nested_require('dsl','parse')
      r8_nested_require('dsl','generate')
      def self.parse(hash)
        Parse.parse(hash)
      end
      def self.node_mappings_in_assembly?(assembly_hash)
        assembly_hash[AssemblyHashKey]
      end
      AssemblyHashKey = 'node_mappings'
    end
  end
end
=begin
"node_mappings"=>{"test1"=>"assembly/dtk::tenant-nginx/tenant"},
=end
