#converts serialized form into object form
module XYZ
  module AssemblyImportMixin
    def add_ports_and_links_during_import(port_links_hash)
      #TODO: midifying from node#clone_post_copy_hook__component(
      #get the link defs/component_ports associated with components in assembly;
      #to determine if need to add internal links and for port processing
return nil
      node_link_defs_info = get_objs(:cols => [:node_link_defs_info])
      component_id = component.id()
      
      ###create needed component ports
      ndx_for_port_update = Hash.new
      component_link_defs = node_link_defs_info.map  do |r|
        link_def = r[:link_def]
        if link_def[:component_component_id] == component_id
          ndx_for_port_update[link_def[:id]] = r
          link_def 
        end
      end.compact

      create_opts = {:returning_sql_cols => [:link_def_id,:id,:display_name,:type,:connected]}
      new_cmp_ports = Port.create_needed_component_ports(component_link_defs,self,component,create_opts)

      #update node_link_defs_info with new ports
      new_cmp_ports.each do |port|
        ndx_for_port_update[port[:link_def_id]].merge!(:port => port)
      end
      LinkDef.create_needed_internal_links(self,component,node_link_defs_info)
    end
  end

  module AssemblyImportClassMixin
    def import(library_idh,assemblies_hash,node_bindings_hash)
      import_hash = {"component" => Hash.new,"node" => Hash.new}
      assemblies_hash.each do |ref,assem|
        import_hash["component"].merge!(AssemblyImportInternal.import_assembly_top(ref,assem))
        import_hash["node"].merge!(AssemblyImportInternal.import_nodes(library_idh,ref,assem,node_bindings_hash))
      end
      import_objects_from_hash(library_idh,import_hash)
      assembly_ref = import_hash["component"].keys.first
      assembly_idh = library_idh.get_child_id_handle(:component,assembly_ref)
      port_links_hash = Hash.new() #TODO: stub
      assembly_idh.create_object().add_ports_and_links_during_import(port_links_hash)
      assembly_idh
    end
    private
    module AssemblyImportInternal
      include AssemblyImportExportCommon
      def self.import_assembly_top(assembly_ref,assembly_hash)
        {assembly_ref => {"display_name" => assembly_hash["name"], "type" => "composite"}}
      end
      def self.import_nodes(library_idh,assembly_ref,assembly_hash,node_bindings_hash)
        module_refs = assembly_hash["modules"]
        node_to_nb_rs = node_bindings_hash.inject(Hash.new) do |h,(k,v)|
          if k =~ Regexp.new("#{assembly_ref}#{Seperators[:assembly_node]}(.+$)")
            node = $1
            h.merge(node => v)
          else
            h
          end
        end
        assembly_hash["nodes"].inject(Hash.new) do |h,(node_hash_ref,node_hash)|
          node_ref = "#{assembly_ref}--#{node_hash_ref}"
          node_output = {
            "display_name" => node_hash_ref, 
            "type" => "stub",
            "*assembly_id" => "/component/#{assembly_ref}" 
          }
          if nb_rs = node_to_nb_rs[node_hash_ref]
            node_output["*node_binding_rs_id"] = "/node_binding_ruleset/#{nb_rs}"
          else
            Log.info("assembly node(#{node_hash_ref}) without a matching node bidning")
          end
#          cmps_output = import_components(library_idh,assembly_ref,module_refs,node_hash["components"])
          cmps_output = import_component_refs(library_idh,module_refs,node_hash["components"])
          unless cmps_output.empty?
#            node_output["component"] = cmps_output
            node_output["component_ref"] = cmps_output
          end
          h.merge(node_ref => node_output)
        end
      end
      def self.import_component_refs(library_idh,module_refs,components_hash)
        #find the reference components and clone
        #TODO: not clear we need the modules if component names are unique w/o modules
        cmp_types = components_hash.map{|cmp|component_type(cmp)}
        sp_hash = {
          :cols => [:id, :display_name, :component_type, :ref, :module_name],
          :filter => [:and, [:oneof, :component_type,cmp_types],
                      [:neq, :library_library_id,nil]] #TODO: think this should pick out specific library
        }
        matching_cmps = Model.get_objs(library_idh.createMH(:component),sp_hash,:keep_ref_cols => true)
        #make sure a match is found for each component
        non_matches = Array.new
        augment_cmps = components_hash.inject(Hash.new) do |h,cmp_hash|
          if match = matching_cmps.find{|match_cmp|match_cmp[:component_type] == component_type(cmp_hash)}
            cmp_ref = {
              "*component_template_id" => "/component/#{match[:ref]}",
              "display_name" => match[:component_type]
            }
            h.merge(match[:component_type] => cmp_ref)
          else 
            non_matches << component_type(cmp_hash)
            h
          end
        end
        #error if one or more matches
        unless non_matches.empty?
          raise Error.new("No component matches for (#{non_matches.join(",")})")
        end
        augment_cmps
      end
      #TODO: deprecate below
      def self.import_components(library_idh,assembly_ref,module_refs,components_hash)
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
            match.merge!("*assembly_id" => "/component/#{assembly_ref}")
            #match.merge!(:library_library_id => library_idh.get_id()) looks like this gets nulled out; see if even need
            h.merge(match[:component_type] => match)
          else 
            non_matches << component_type(cmp_hash)
            h
          end
        end
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
