module DTK; class ServiceModule
  class AssemblyImport
    module PortMixin
     private
      def add_port_and_port_links()
        #port links can only be imported in after ports created
        #add ports to assembly nodes
        db_updates_port_links = Hash.new
        version_field = @module_branch.get_field?(:version)
        @ndx_assembly_hashes.each do |ref,assembly|
          qualified_ref = Internal.internal_assembly_ref__add_version(ref,version_field)
          assembly_idh = @container_idh.get_child_id_handle(:component,qualified_ref)
          ports = add_ports_during_import(assembly_idh)
          db_updates_port_links.merge!(import_port_links(assembly_idh,qualified_ref,assembly,ports))
          ports.each{|p|@ndx_ports[p[:id]] = p}
        end
        #Within Internal.import_port_links does the mark as complete for port links
        Model.input_hash_content_into_model(@container_idh,{"component" => db_updates_port_links})
      end

      def add_ports_during_import(assembly_idh)
        ret = Array.new
        #get the link defs/component_ports associated with components in assembly;
        #to determine if need to add internal links and for port processing
        assembly = assembly_idh.create_object()
        #compute augmented link def info
        link_defs_info = assembly.get_objs(:cols => [:template_link_defs_info])
        return ret if link_defs_info.empty?
        sp_hash = {
          :cols => [:id,:group_id,:link_def_id,:remote_component_type],
          :filter => [:oneof, :link_def_id, link_defs_info.map{|r|(r[:link_def]||{})[:id]}.compact]
        }
        rows = Model.get_objs(assembly_idh.createMH(:link_def_link),sp_hash)
        ndx_link_def_links = rows.inject(Hash.new){|h,r|h.merge(r[:link_def_id] => r)}
        link_defs_info.each do |r|
          if link_def = r[:link_def]
            if link = ndx_link_def_links[link_def[:id]]
              (link_def[:link_def_links] ||= Array.new) << link
            end
          end
        end

        create_opts = {:returning_sql_cols => [:link_def_id,:id,:display_name,:type,:connected]}
        create_assembly_template_ports?(assembly,link_defs_info,create_opts)
      end

      def create_assembly_template_ports?(assembly,link_defs_info,opts={})
        ret = Array.new
        return ret if link_defs_info.empty?

        #make sure duplicate ports are pruned; tried to use :duplicate_refs => :prune_duplicates but bug; so explicitly looking fro existing ports
        sp_hash = {
          :cols => ([:node_node_id,:ref,:node] + (opts[:returning_sql_cols]||[])).uniq,
          :filter => [:oneof, :node_node_id, link_defs_info.map{|ld|ld[:node][:id]}]
        }

        port_mh = assembly.id_handle.create_childMH(:port)
        ndx_existing_ports = Hash.new
        Model.get_objs(port_mh,sp_hash,:keep_ref_cols => true).each do |r|
          (ndx_existing_ports[r[:node_node_id]] ||= Hash.new)[r[:ref]] = {:port => r,:matched => false}
        end 

        #Need to index by node because create_from_rows can only insert under one parent
        ndx_rows = Hash.new
        link_defs_info.each do |ld_info|
          next unless link_def = ld_info[:link_def]
          cmp = ld_info[:nested_component]
          node = ld_info[:node]
          component_type = cmp[:component_type]
          type = 
            if link_def[:has_external_link]
              link_def[:has_internal_link] ? "component_internal_external" : "component_external"
            else #will be just ld_info[:has_internal_link]
              "component_internal"
            end

          dir = Port.direction_from_local_remote(link_def[:local_or_remote])
          ref = Port.ref_from_component_and_link_def(type,component_type,link_def,dir)
          if existing_port_info = (ndx_existing_ports[node[:id]]||{})[ref]
            existing_port_info[:matched] = true
            ret << existing_port_info[:port]
          else
            display_name = ref #TODO: rather than encoded name to component i18n name, make add a structured column likne name_context
            location_asserted = Port.ret_location_asserted(component_type,link_def[:link_type])
            row = {
              :ref => ref,
              :display_name => display_name,
              :direction => dir,
              :link_def_id => link_def[:id],
              :node_node_id => node[:id],
              :type => type
            }
            row[:location_asserted] = location_asserted if location_asserted
            
            pntr = ndx_rows[node[:id]] ||= {:node => node, :create_rows => Array.new}
            pntr[:create_rows] << row
          end
        end

        new_rows = Array.new
        ndx_rows.values.each do |r|
          port_mh = r[:node].model_handle_with_auth_info.create_childMH(:port)
          new_rows += Model.create_from_rows(port_mh,r[:create_rows],opts)
        end

        #delete any existing ports that match what is being put in now
        port_idhs_to_delete = Array.new
        ndx_existing_ports.each_value do |inner_ndx_ports|
          inner_ndx_ports.each_value do |port_info|
            unless port_info[:matched]
              port_idhs_to_delete << port_info[:port].id_handle()
            end
          end
        end
        unless port_idhs_to_delete.empty?()
          delete_instances(port_idhs_to_delete)
        end

        #for new rows need to splice in node info
        unless new_rows.empty?
          sp_hash = {
            :cols => [:id,:node],
            :filter => [:oneof, :node_node_id, new_rows.map{|p|p[:parent_id]}]
          }
          ndx_port_node = Model.get_objs(port_mh,sp_hash).inject(Hash.new) do |h,r|
            h.merge(r[:id] => r[:node])
          end
          new_rows.each{|r|r.merge!(:node => ndx_port_node[r[:id]])}
        end
        ret + new_rows
      end

      def import_port_links(assembly_idh,assembly_ref,assembly_hash,ports)
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
        port_links.mark_as_complete(:assembly_id=>@existing_assembly_ids)
        {assembly_ref => {"port_link" => port_links}}
      end
    end
  end
end;end
