#converts serialized form into object form
module DTK; class ServiceModule
  class AssemblyImport
    def initialize(container_idh,module_branch,module_name,module_version_constraints)
      @container_idh = container_idh
      @db_updates_assemblies = DBUpdateHash.new("component" => DBUpdateHash.new,"node" => DBUpdateHash.new)
      @ndx_ports = Hash.new
      @ndx_assembly_hashes = Hash.new #indexed by ref
      @module_branch = module_branch
      @module_name = module_name
      @service_module = get_service_module(container_idh,module_name)
      @module_version_constraints = module_version_constraints
    end
    def add_assemblies(assemblies_hash,node_bindings_hash)
      dangling_errors = ErrorUsage::DanglingComponentRefs::Aggregate.new()
      assemblies_hash.each do |ref,assem|
        dangling_errors.aggregate_errors! do
          @db_updates_assemblies["component"].merge!(Internal.import_assembly_top(ref,assem,@module_branch,@module_name))
          @db_updates_assemblies["node"].merge!(Internal.import_nodes(@container_idh,@module_branch,ref,assem,node_bindings_hash,@module_version_constraints))
          @ndx_assembly_hashes[ref] ||= assem
        end
      end
      dangling_errors.raise_error?()
    end

    def import()
      module_branch_id = @module_branch[:id]
      mark_as_complete_cmp_constraint = {:module_branch_id=>module_branch_id} #so only delete extra components that belong to same module
      @db_updates_assemblies["component"].mark_as_complete(mark_as_complete_cmp_constraint)

      sp_hash = {
        :cols => [:id],
        :filter => [:eq,:module_branch_id, module_branch_id]
      }
      existing_assembly_ids = Model.get_objs(@container_idh.createMH(:component),sp_hash).map{|r|r[:id]}
      mark_as_complete_node_constraint = {:assembly_id=>existing_assembly_ids}
      @db_updates_assemblies["node"].mark_as_complete(mark_as_complete_node_constraint,:apply_recursively => true)

      Model.input_hash_content_into_model(@container_idh,@db_updates_assemblies)

      #port links can only be imported in after ports created
      #add ports to assembly nodes
      db_updates_port_links = Hash.new
      version_field = @module_branch.get_field?(:version)
      @ndx_assembly_hashes.each do |ref,assembly|
        qualified_ref = Internal.internal_assembly_ref__add_version(ref,version_field)
        assembly_idh = @container_idh.get_child_id_handle(:component,qualified_ref)
        ports = add_ports_during_import(assembly_idh)
        db_updates_port_links.merge!(Internal.import_port_links(assembly_idh,qualified_ref,assembly,ports,existing_assembly_ids))
        ports.each{|p|@ndx_ports[p[:id]] = p}
      end
      #Within Internal.import_port_links does the mark as complete for port links
      Model.input_hash_content_into_model(@container_idh,{"component" => db_updates_port_links})
    end

    def ports()
      @ndx_ports.values()
    end

    def augmented_assembly_nodes()
      @augmented_assembly_nodes ||= @service_module.get_augmented_assembly_nodes()
    end

    def self.augment_with_parsed_port_names!(ports)
      ports.each do |p|
        p[:parsed_port_name] ||= Port.parse_external_port_display_name(p[:display_name])
      end
    end

   private
    def get_service_module(container_idh,module_name)
      container_idh.create_object().get_service_module(module_name)
    end

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
      def self.import_assembly_top(serialized_assembly_ref,assembly_hash,module_branch,module_name)
        version_field = module_branch.get_field?(:version)
        assembly_ref = internal_assembly_ref__with_version(serialized_assembly_ref,version_field)
        {
          assembly_ref => {
            "display_name" => assembly_hash["name"], 
            "type" => "composite",
            "module_branch_id" => module_branch[:id],
            "version" => version_field,
            "component_type" => Assembly.ret_component_type(module_name,assembly_hash["name"])
          }
        }
      end
      def self.import_port_links(assembly_idh,assembly_ref,assembly_hash,ports,existing_assembly_ids)
        #augment ports with parsed display_name
        AssemblyImport.augment_with_parsed_port_names!(ports)

        port_links = (assembly_hash["port_links"]||[]).inject(DBUpdateHash.new) do |h,pl|
          input = AssemblyImportPortRef.parse(pl.values.first)
          output = AssemblyImportPortRef.parse(pl.keys.first)
          input_id = input.matching_id(ports)
          output_id = output.matching_id(ports)
          pl_ref = PortLink.ref_from_ids(input_id,output_id)
          pl_hash = {"input_id" => input_id,"output_id" => output_id, "assembly_id" => assembly_idh.get_id()}
          h.merge(pl_ref => pl_hash)
        end
        port_links.mark_as_complete(:assembly_id=>existing_assembly_ids)
        {assembly_ref => {"port_link" => port_links}}
      end

      def self.import_nodes(container_idh,module_branch,assembly_ref,assembly_hash,node_bindings_hash,version_constraints)
        an_sep = Seperators[:assembly_node]
        node_to_nb_rs = (node_bindings_hash||{}).inject(Hash.new) do |h,(ser_assem_node,v)|
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

        #compute nb_rs_to_id
        nb_rs_to_id = Hash.new
        unless node_to_nb_rs.empty?
          filter = [:oneof, :ref, node_to_nb_rs.values]
          #TODO: hard coded that nodding in public library
          nb_rs_containter = Library.get_public_library(container_idh.createMH(:library))
          nb_rs_to_id = nb_rs_containter.get_node_binding_rulesets(filter).inject(Hash.new) do |h,r|
            h.merge(r[:ref] => r[:id])
          end
        end

        dangling_errors = ErrorUsage::DanglingComponentRefs::Aggregate.new()
        version_field = module_branch.get_field?(:version)
        assembly_ref_with_version = internal_assembly_ref__add_version(assembly_ref,version_field)
        ret = assembly_hash["nodes"].inject(Hash.new) do |h,(node_hash_ref,node_hash)|
          dangling_errors.aggregate_errors!(h) do
            node_ref = "#{assembly_ref_with_version}--#{node_hash_ref}"
            node_output = {
              "display_name" => node_hash_ref, 
              "type" => "stub",
              "*assembly_id" => "/component/#{assembly_ref_with_version}" 
            }
            if nb_rs = node_to_nb_rs[node_hash_ref]
              if nb_rs_id = nb_rs_to_id[nb_rs]
                node_output["node_binding_rs_id"] = nb_rs_id
              else
                #TODO: extend dangling_errors.aggregate_errors to handle this
                raise ErrorUsage.new("Bad node reference #{nb_rs})")
              end
            else
              node_output["node_binding_rs_id"] = nil
            end
            cmps_output = import_component_refs(container_idh,assembly_hash["name"],node_hash["components"],version_constraints)
            unless cmps_output.empty?
              node_output["component_ref"] = cmps_output
            end
            h.merge(node_ref => node_output)
          end
        end
        dangling_errors.raise_error?()
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

      def self.internal_assembly_ref__with_version(serialized_assembly_ref,version_field)
        module_name,assembly_name = parse_serialized_assembly_ref(serialized_assembly_ref)
        Assembly.internal_assembly_ref(module_name,assembly_name,version_field)
      end
      def self.internal_assembly_ref__without_version(serialized_assembly_ref)
        module_name,assembly_name = parse_serialized_assembly_ref(serialized_assembly_ref)
        Assembly.internal_assembly_ref(module_name,assembly_name)
      end
      class << self
       public
        def internal_assembly_ref__add_version(assembly_ref,version_field)
          Assembly.internal_assembly_ref__add_version(assembly_ref,version_field)
        end
      end

      def self.import_component_refs(container_idh,assembly_name,components_hash,version_constraints)
        ret = components_hash.inject(Hash.new) do |h,cmp_hash|
          parse = component_ref_parse(cmp_hash)
          cmp_ref = Aux::hash_subset(parse,[:component_type,:version,:display_name])
          if cmp_ref[:version]
            cmp_ref[:has_override_version] = true
          end
          h.merge(parse[:ref] => cmp_ref)
        end
        #find and insert component template ids
        #just set component_template_id
        version_constraints.set_matching_component_template_info!(ret.values, :donot_set_component_templates=>true)
        ret
      end

      def self.component_ref_parse(cmp)
        term = (cmp.kind_of?(Hash) ?  cmp.keys.first : cmp).gsub(Regexp.new(Seperators[:module_component]),"__")
        if term =~ Regexp.new("(^.+)#{Seperators[:component_version]}(.+$)")
          type = $1; version = $2
        else
          type = term; version = nil
        end
        ret = {:component_type => type, :ref => term, :display_name => term}
        ret.merge!(:version => version) if version
        ret
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
