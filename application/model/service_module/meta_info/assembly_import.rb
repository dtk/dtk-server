#converts serialized form into object form
module DTK; class ServiceModule
  class AssemblyImport
    def initialize(library_idh)
      @library_idh = library_idh
      @db_updates_assemblies = DBUpdateHash.new("component" => DBUpdateHash.new,"node" => DBUpdateHash.new)
      @ndx_ports = Hash.new
      @ndx_assembly_hashes = Hash.new #indexed by ref
      @ndx_module_branch_ids = Hash.new
    end
    def add_assemblies(module_branch_idh,module_name,assemblies_hash,node_bindings_hash)
      @ndx_module_branch_ids[module_branch_idh.get_id()] ||= true
      assemblies_hash.each do |ref,assem|
        @db_updates_assemblies["component"].merge!(Internal.import_assembly_top(ref,assem,module_branch_idh,module_name))
        @db_updates_assemblies["node"].merge!(Internal.import_nodes(@library_idh,ref,assem,node_bindings_hash))
        @ndx_assembly_hashes[ref] ||= assem
      end
    end

    def import()
      mark_as_complete_constraint = {:module_branch_id=>@ndx_module_branch_ids.keys} #so only delete extra components that belong to same module
      @db_updates_assemblies["component"].mark_as_complete(mark_as_complete_constraint)
      Model.import_objects_from_hash(@library_idh,@db_updates_assemblies)

      #port links can only be imported in after ports created
      #add ports to assembly nodes
      db_updates_port_links = Hash.new
      @ndx_assembly_hashes.each do |ref,assembly|
        assembly_idh = @library_idh.get_child_id_handle(:component,ref)
        ports = add_ports_during_import(assembly_idh)
        db_updates_port_links.merge!(Internal.import_port_links(assembly_idh,ref,assembly,ports))
        ports.each{|p|@ndx_ports[p[:id]] = p}
      end
      Model.import_objects_from_hash(@library_idh,{"component" => db_updates_port_links})
    end

    def ports()
      @ndx_ports.values()
    end

    def self.import_add_on_port_links(ports,add_on_port_links,assembly_name,sub_assembly_name)
      Internal.import_add_on_port_links(ports,add_on_port_links,assembly_name,sub_assembly_name)
    end

   private
    def add_ports_during_import(assembly_idh)
      #get the link defs/component_ports associated with components in assembly;
      #to determine if need to add internal links and for port processing
      assembly = assembly_idh.create_object()
      link_defs_info = assembly.get_objs(:cols => [:template_link_defs_info])
      create_opts = {:returning_sql_cols => [:link_def_id,:id,:display_name,:type,:connected]}
      Port.create_assembly_template_ports?(assembly,link_defs_info,create_opts)
    end

    #TODO: now that converted top level to a call; dont need these internal modules
    module Internal
      include AssemblyImportExportCommon
      def self.import_assembly_top(serialized_assembly_ref,assembly_hash,module_branch_idh,module_name)
        assembly_ref = internal_assembly_ref(serialized_assembly_ref)
        {
          assembly_ref => {
            "display_name" => assembly_hash["name"], 
            "type" => "composite",
            "module_branch_id" => module_branch_idh.get_id(),
            "component_type" => Assembly.ret_component_type(module_name,assembly_hash["name"])
          }
        }
      end
      def self.import_port_links(assembly_idh,assembly_ref,assembly_hash,ports)
        #augment ports with parsed display_name
        augment_with_parsed_port_names!(ports)

        port_links = (assembly_hash["port_links"]||[]).inject(Hash.new) do |h,pl|
          input = AssemblyImportPortRef.parse(pl.values.first)
          output = AssemblyImportPortRef.parse(pl.keys.first)
          input_id = input.matching_id(ports)
          output_id = output.matching_id(ports)
          pl_ref = PortLink.ref_from_ids(input_id,output_id)
          pl_hash = {"input_id" => input_id,"output_id" => output_id, "assembly_id" => assembly_idh.get_id()}
          h.merge(pl_ref => pl_hash)
        end
        {assembly_ref => {"port_link" => port_links}}
      end

      def self.import_nodes(library_idh,assembly_ref,assembly_hash,node_bindings_hash)
        module_refs = assembly_hash["modules"]
        an_sep = Seperators[:assembly_node]
        node_to_nb_rs = (node_bindings_hash||{}).inject(Hash.new) do |h,(ser_assem_node,v)|
          merge_hash = Hash.new
          if ser_assem_node =~ Regexp.new("(^[^#{an_sep}]+)#{an_sep}(.+$)")
            serialized_assembly_ref = $1
            node = $2
            if assembly_ref == internal_assembly_ref(serialized_assembly_ref)
              merge_hash = {node => v}
            end
          end
          h.merge(merge_hash)
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
          end
          cmps_output = import_component_refs(library_idh,assembly_hash["name"],module_refs,node_hash["components"])
          unless cmps_output.empty?
            node_output["component_ref"] = cmps_output
          end
          h.merge(node_ref => node_output)
        end
      end

     private
      def self.import_add_on_port_links(ports,add_on_port_links,assembly_name,sub_assembly_name)
        ret = Hash.new
        return ret if (add_on_port_links||[]).empty?
        #augment ports with parsed display_name
        augment_with_parsed_port_names!(ports)
        assembly_names = [assembly_name,sub_assembly_name]
        add_on_port_links.each do |ao_pl_ref,ao_pl|
          link = ao_pl["link"]
          input_assembly,input_port = AssemblyImportPortRef::AddOn.parse(link.values.first,assembly_names)
          output_assembly,output_port = AssemblyImportPortRef::AddOn.parse(link.keys.first,assembly_names)
          input_id = input_port.matching_id(ports)
          output_id = output_port.matching_id(ports)
          output_is_local = (output_assembly == assembly_name) 
          pl_hash = {"input_id" => input_id,"output_id" => output_id, "output_is_local" => output_is_local, "required" => ao_pl["required"]}
          ret.merge!(ao_pl_ref => pl_hash)
        end
        ret
      end

     private
      #return [module_name,assembly_name]
      def self.parse_serialized_assembly_ref(ref)
        if ref =~ /(^.+)::(.+$)/
          [$1,$2]
        elsif ref =~ /(^[^-]+)-(.+$)/ #TODO: this can be eventually deprecated
          [$1,$2]
        else
          raise Error.new("Unexpected form for serialized assembly ref (#{ref})")
        end
      end

      def self.internal_assembly_ref(serialized_assembly_ref)
        module_name,assembly_name = parse_serialized_assembly_ref(serialized_assembly_ref)
        Assembly.internal_assembly_ref(module_name,assembly_name)
      end

      def self.augment_with_parsed_port_names!(ports)
        ports.each do |p|
          p[:parsed_port_name] ||= Port.parse_external_port_display_name(p[:display_name])
        end
      end

      def self.import_component_refs(library_idh,assembly_name,module_refs,components_hash)
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
          raise ErrorUsage.new("No component matches for (#{non_matches.join(",")}) found in assembly (#{assembly_name})")
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
end; end
