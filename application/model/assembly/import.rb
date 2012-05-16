#converts serialized form into object form
module XYZ
  module AssemblyImportClassMixin
    def import(library_idh,assemblies_hash,node_bindings_hash)
      import_hash = {"component" => Hash.new,"node" => Hash.new}
      assemblies_hash.each do |ref,assem|
        import_hash["component"].merge!(AssemblyImportInternal.import_assembly(ref,assem))
        import_hash["node"].merge!(AssemblyImportInternal.import_assembly_nodes(ref,assem,node_bindings_hash))
      end
      import_objects_from_hash(library_idh,import_hash)
    end
    private
    module AssemblyImportInternal
      def self.import_assembly(assembly_ref,assembly_hash)
        {assembly_ref => {"display_name" => assembly_hash["name"]}}
      end
      def self.import_assembly_nodes(assembly_ref,assembly_hash,node_bindings_hash)
        assembly_hash["nodes"].inject(Hash.new) do |h,(node_hash_ref,node_hash)|
          node_ref = "#{assembly_ref}--#{node_hash_ref}"
          node_hash = {
            "display_name" => node_hash_ref, 
            "type" => "stub",
            "*assembly_id" => "/component/#{assembly_ref}"
          }
          h.merge(node_ref => node_hash)
        end
      end
    end
  end
end
