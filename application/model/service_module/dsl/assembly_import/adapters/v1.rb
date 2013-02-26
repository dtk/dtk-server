module DTK; class ServiceModule
  class AssemblyImport
    class V1 < self
      def self.assembly_iterate(module_name,hash_content,&block)
        assemblies_hash = hash_content["assemblies"].values.inject(Hash.new) do |h,assembly_info|
          h.merge(ServiceModule.assembly_ref(module_name,assembly_info["name"]) => assembly_info)
        end
        node_bindings_hash = hash_content["node_bindings"]
        block.call(assemblies_hash,node_bindings_hash)
      end

     private
      include AssemblyImportExportCommon

      def self.ret_node_to_node_binding_rs(assembly_ref,node_bindings_hash)
        an_sep = Seperators[:assembly_node]
        (node_bindings_hash||{}).inject(Hash.new) do |h,(ser_assem_node,v)|
          merge_hash = Hash.new
          if ser_assem_node =~ Regexp.new("(^[^#{an_sep}]+)#{an_sep}(.+$)")
            serialized_assembly_ref = $1
            node = $2
            if assembly_ref == internal_assembly_ref__without_version(serialized_assembly_ref)
              merge_hash = {node => v}
            end
          end
          h.merge(merge_hash)
        end
      end
      
      def self.internal_assembly_ref__without_version(serialized_assembly_ref)
        module_name,assembly_name = parse_serialized_assembly_ref(serialized_assembly_ref)
        Assembly.internal_assembly_ref(module_name,assembly_name)
      end

    end
  end
end; end
