#converts serialized form into object form
module XYZ
  module AssemblyImportClassMixin
    def import(library_idh,assemblies_hash,node_bindings_hash)
      import_hash = {"component" => Hash.new,"node" => Hash.new}
      assemblies_hash.each do |ref,assem|
        import_hash["component"].merge!(AssemblyImportInternal.import_assembly_top(ref,assem))
        import_hash["node"].merge!(AssemblyImportInternal.import_nodes(library_idh,ref,assem,node_bindings_hash))
      end
      import_objects_from_hash(library_idh,import_hash)
      #port links can only be imported in after ports created
      #add ports to assembly nodes
      pl_import_hash = Hash.new
      assemblies_hash.each do |ref,assem|
        assembly_idh = library_idh.get_child_id_handle(:component,ref)
        ports = assembly_idh.create_object().add_ports_during_import()
        pl_import_hash.merge!(AssemblyImportInternal.import_port_links(assembly_idh,ref,assem,ports))
      end

      import_objects_from_hash(library_idh,{"component" => pl_import_hash})

      ret = Array.new
      ret
    end
    private
    module AssemblyImportInternal
      include AssemblyImportExportCommon
      def self.import_assembly_top(assembly_ref,assembly_hash)
        {assembly_ref => {"display_name" => assembly_hash["name"], "type" => "composite"}}
      end
      def self.import_port_links(assembly_idh,assembly_ref,assembly_hash,ports)
        #augment ports with parsed display_name
        ports.each{|p|p.merge!(:parsed_port_name => Port.parse_external_port_display_name(p[:display_name]))}

        (assembly_hash["port_links"]||[]).inject(Hash.new) do |h,pl|
          input = AssemblyImportPortRef.parse(pl.values.first)
          output = AssemblyImportPortRef.parse(pl.keys.first)
          input_id = input.matching_id(ports)
          output_id = output.matching_id(ports)
          pl_ref = PortLink.ref_from_ids(input_id,output_id)
          pl_hash = {"input_id" => input_id,"output_id" => output_id, "assembly_id" => assembly_idh.get_id()}
          h.merge(assembly_ref => {"port_link" => {pl_ref => pl_hash}})
        end
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
            Log.info("assembly node(#{node_hash_ref}) without a matching node binding")
          end
          cmps_output = import_component_refs(library_idh,module_refs,node_hash["components"])
          unless cmps_output.empty?
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
            cmp_template_relative_uri = "/component/#{match[:ref]}" 
            cmp_ref = {
              "*component_template_id" => cmp_template_relative_uri,
              "display_name" => match[:component_type]
            }
            attr_overrides = attribute_overrides(cmp_hash,cmp_template_relative_uri)
            unless attr_overrides.empty?
              cmp_ref.merge!("attribute_override" => attr_overrides)
            end
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
      def self.component_type(cmp)
        (cmp.kind_of?(Hash) ?  cmp.keys.first : cmp).gsub(Regexp.new(Seperators[:module_component]),"__")
      end

      def self.attribute_overrides(cmp,cmp_template_relative_uri)
        ret = Hash.new
        return ret unless cmp.kind_of?(Hash)
        cmp.values.first.inject(Hash.new) do |h,(name,value)|
          attr_template_id = "#{cmp_template_relative_uri}/attribute/#{name}"
          h.merge(name => {"display_name" => name, "attribute_value" => value, "*attribute_template_id" => attr_template_id}) 
        end       
      end
    end
  end
  module AssemblyImportMixin
    def add_ports_during_import()
      #get the link defs/component_ports associated with components in assembly;
      #to determine if need to add internal links and for port processing
      link_defs_info = get_objs(:cols => [:template_link_defs_info])
      create_opts = {:returning_sql_cols => [:link_def_id,:id,:display_name,:type,:connected]}
      Port.create_needed_assembly_template_ports(self,link_defs_info,create_opts)
    end
  end
end
