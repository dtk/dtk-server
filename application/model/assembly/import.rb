#converts serialized form into object form
module XYZ
  module AssemblyImportClassMixin
    def import(library_idh,assemblies_hash,node_bindings_hash)
      import_hash = {"component" => Hash.new,"node" => Hash.new}
      assemblies_hash.each do |ref,assem|
        import_hash["component"].merge!(AssemblyImportInternal.import_assembly_top(ref,assem))
        import_hash["node"].merge!(AssemblyImportInternal.import_nodes(library_idh,ref,assem,node_bindings_hash))
      end
##      import_objects_from_hash(library_idh,import_hash)
pp import_hash
    end
    private
    module AssemblyImportInternal
      include AssemblyImportExportCommon
      def self.import_assembly_top(assembly_ref,assembly_hash)
        {assembly_ref => {"display_name" => assembly_hash["name"]}}
      end
      def self.import_nodes(library_idh,assembly_ref,assembly_hash,node_bindings_hash)
        module_refs = assembly_hash["modules"]
        assembly_hash["nodes"].inject(Hash.new) do |h,(node_hash_ref,node_hash)|
          node_ref = "#{assembly_ref}--#{node_hash_ref}"
          node_output = {
            "display_name" => node_hash_ref, 
            "type" => "stub",
            "*assembly_id" => "/component/#{assembly_ref}"
          }
          cmps_output = import_components(library_idh,module_refs,node_hash["components"])
          unless cmps_output.empty?
            node_output["component"] = cmps_output
          end
          h.merge(node_ref => node_output)
        end
      end
      def self.import_components(library_idh,module_refs,components_hash)
        #find the reference components and clone
        #TODO: not clear we need the modules if component names are unique w/o modules
        #TODO: may eventually move to ref model for components in an assembly
        cmp_types = components_hash.map{|cmp|component_type(cmp)}
        sp_hash = {
          :cols => Component.common_columns() + [:module_name],
          :filter => [:and, [:oneof, :component_type,cmp_types],
                      [:neq, :library_library_id,nil]] #TODO: think this should pick out specific library
        }
        matching_cmps = Model.get_objs(library_idh.createMH(:component),sp_hash)
        #make sure a match is found for each component
        non_matches = Array.new
        augment_cmps = components_hash.inject(Hash.new) do |h,cmp_hash|
          if match = matching_cmps.find{|match_cmp|match_cmp[:component_type] == component_type(cmp_hash)}
            [:id,:implementation,:assembly_id,:node_node_id].each{|k|match.delete(k)}
            match.merge!("*assembly_id" => "/component/#{assembly_ref}",:library_library_id => library_idh.get_id())
            h.merge(match[:component_type] => match)
          else 
            non_matches << component_type(cmp_hash)
            h
          end
        end.compact
        #error if one or more matches
        unless non_matches.empty?
          raise Error.new("No component matches for (#{non_matches.join(",")})")
        end
        augment_cmps
      end
        def self.component_type(cmp)
          (cmp.kind_of?(Hash) ?  cmp.keys.first : cmp).gsub(Regexp.new(Seperators[:module_component]),"__")
        end
    end
  end
end
