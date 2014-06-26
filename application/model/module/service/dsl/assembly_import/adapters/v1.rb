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

      def self.import_port_links(assembly_idh,assembly_ref,assembly_hash,ports)
        # augment ports with parsed display_name
        augment_with_parsed_port_names!(ports)
        
        port_links = (assembly_hash["port_links"]||[]).inject(DBUpdateHash.new) do |h,pl|
          input = PortRef.parse(pl.values.first)
          output = PortRef.parse(pl.keys.first)
          input_id = input.matching_id(ports)
          output_id = output.matching_id(ports)
          pl_ref = PortLink.ref_from_ids(input_id,output_id)
          pl_hash = {"input_id" => input_id,"output_id" => output_id, "assembly_id" => assembly_idh.get_id()}
          h.merge(pl_ref => pl_hash)
        end
        port_links.mark_as_complete(:assembly_id=>@existing_assembly_ids)
        {assembly_ref => {"port_link" => port_links}}
      end

     private
      include ServiceDSLCommonMixin

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

      def self.ret_attribute_overrides(cmp_input)
        (cmp_input.kind_of?(Hash) && cmp_input.values.first)||{}
      end

    end
  end
end; end
