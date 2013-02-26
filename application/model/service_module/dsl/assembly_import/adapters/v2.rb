module DTK; class ServiceModule
  class AssemblyImport
    class V2 < self
      def self.assembly_iterate(module_name,hash_content,&block)
        name = hash_content["name"]
        assemblies_hash = {ServiceModule.assembly_ref(module_name,name) => hash_content["assembly"].merge("name" => name)}
        node_bindings_hash = hash_content["node_bindings"]
        block.call(assemblies_hash,node_bindings_hash)
      end

     private
      include AssemblyImportExportCommon

      def self.ret_node_to_node_binding_rs(assembly_ref,node_bindings_hash)
        (node_bindings_hash||{}).inject(Hash.new) do |h,(node,v)|
          merge_hash = 
            if v.kind_of?(String) then {node => v}
            elsif v.kind_of?(Hash)
              Log.error("Not implemented yet have node bindings with explicit properties")
              Hash.new
            else
              raise Error.new("Unexpected form of node binding")
            end
          h.merge(merge_hash)
        end
      end
      
    end
  end
end; end
