#converts serialized form into object form
module XYZ
  module AssemblyImportClassMixin
    def import(library_idh,assemblies_hash,node_bindings_hash)
      import_hash = {"component" => Hash.new,"node" => Hash.new}
      assemblies_hash.each do |ref,assem|
        import_hash["component"].merge!(AssemblyImportInternal.import_assembly(ref,assem))
        import_hash["node"].merge!(AssemblyImportInternal.import_nodes(ref,assem,node_bindings_hash))
      end
##      import_objects_from_hash(library_idh,import_hash)
pp import_hash
    end
    private
    module AssemblyImportInternal
      include AssemblyImportExportCommon
      def self.import_assembly(assembly_ref,assembly_hash)
        {assembly_ref => {"display_name" => assembly_hash["name"]}}
      end
      def self.import_nodes(assembly_ref,assembly_hash,node_bindings_hash)
        module_refs = assembly_hash["modules"]
        assembly_hash["nodes"].inject(Hash.new) do |h,(node_hash_ref,node_hash)|
          node_ref = "#{assembly_ref}--#{node_hash_ref}"
          cmps_output = import_components(module_refs,node_hash["components"])
          node_output = {
            "display_name" => node_hash_ref, 
            "type" => "stub",
            "*assembly_id" => "/component/#{assembly_ref}"
          }
          h.merge(node_ref => node_output)
        end
      end
      def self.import_components(module_refs,components_hash)
        nil #TODO: stub
      end
    end
  end
end
