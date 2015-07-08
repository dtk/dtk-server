module DTK; class ServiceModule
  class AssemblyImport
    module PortMixin
      def ports
        @ndx_ports.values()
      end

      private

      def add_port_and_port_links
        # port links can only be imported in after ports created
        # add ports to assembly nodes
        db_updates_port_links = {}
        @ndx_assembly_hashes.each do |assembly_ref,assembly|
          assembly_idh = @container_idh.get_child_id_handle(:component,assembly_ref)
          ports = add_needed_ports(assembly_idh)
          version_proc_class = @ndx_version_proc_classes[assembly_ref]
          opts = {}
          if file_path = @ndx_assembly_file_paths[assembly_ref]
            opts[:file_path] = file_path
          end
          port_links = version_proc_class.import_port_links(assembly_idh,assembly_ref,assembly,ports,opts)
          return port_links if ParsingError.is_error?(port_links)

          db_updates_port_links.merge!(port_links)
          ports.each{|p|@ndx_ports[p[:id]] = p}
        end
        # Within import_port_links does the mark as complete for port links
        Model.input_hash_content_into_model(@container_idh,"component" => db_updates_port_links)
      end
    end

    def add_needed_ports(assembly_idh)
      ret = []
      assembly = assembly_idh.create_object()
      link_defs_info = LinkDef::Info.get_link_def_info(assembly)

      create_opts = {returning_sql_cols: [:link_def_id,:id,:display_name,:type,:connected]}
      PortProcessing.create_assembly_template_ports?(link_defs_info,create_opts)
    end
  end

  module PortProcessing
    def self.create_assembly_template_ports?(link_defs_info,opts={})
      ret = []
      return ret if link_defs_info.empty?
      port_mh = link_defs_info.first.model_handle(:port)
      ndx_existing_ports = get_ndx_existing_ports(port_mh,link_defs_info,opts)
      # create create-hashes for both local side and remote side ports
      # Need to index by node because create_from_rows can only insert under one parent
      ndx_rows = {}
      link_defs_info.each do |ld_info|
        if link_def = ld_info[:link_def]
          node = ld_info[:node]
          cmp_ref = ld_info[:component_ref]
          port = Port.ret_port_create_hash(link_def,node,ld_info[:nested_component],component_ref: cmp_ref)
          if existing_port_info = (ndx_existing_ports[node[:id]]||{})[port[:ref]]
            existing_port_info[:matched] = true
            ret << existing_port_info[:port]
          else
            pntr = ndx_rows[node[:id]] ||= {node: node, ndx_create_rows: {}}
            pntr[:ndx_create_rows][port[:ref]] ||= port
          end
        end
      end

      # add the remote ports
      link_defs_info.generate_link_def_link_pairs do |link_def,link|
        remote_component_type = link[:remote_component_type]
        link_defs_info.select{|r|r[:nested_component][:component_type] == remote_component_type}.each do |matching_node_cmp|
          node = matching_node_cmp[:node]
          component = matching_node_cmp[:nested_component]
          cmp_ref = matching_node_cmp[:component_ref]
          port = Port.ret_port_create_hash(link_def,node,component,remote_side: true,component_ref: cmp_ref)
          if existing_port_info = (ndx_existing_ports[node[:id]]||{})[port[:ref]]
            existing_port_info[:matched] = true
            ret << existing_port_info[:port]
          else
            pntr = ndx_rows[node[:id]] ||= {node: node, ndx_create_rows: {}}
            pntr[:ndx_create_rows][port[:ref]] ||= port
          end
        end
      end

      new_rows = []
      ndx_rows.values.each do |r|
        create_port_mh = r[:node].model_handle_with_auth_info.create_childMH(:port)
        new_rows += Model.create_from_rows(create_port_mh,r[:ndx_create_rows].values,opts)
      end

      # delete any existing ports that match what is being put in now
      port_idhs_to_delete = []
      ndx_existing_ports.each_value do |inner_ndx_ports|
        inner_ndx_ports.each_value do |port_info|
          unless port_info[:matched]
            port_idhs_to_delete << port_info[:port].id_handle()
          end
        end
      end
      unless port_idhs_to_delete.empty?()
        Model.delete_instances(port_idhs_to_delete)
      end

      # for new rows need to splice in node info
      unless new_rows.empty?
        sp_hash = {
          cols: [:id,:node],
          filter: [:oneof, :node_node_id, new_rows.map{|p|p[:parent_id]}]
        }
        ndx_port_node = Model.get_objs(port_mh,sp_hash).inject({}) do |h,r|
          h.merge(r[:id] => r[:node])
        end
        new_rows.each{|r|r.merge!(node: ndx_port_node[r[:id]])}
      end
      ret + new_rows
    end

    private

    # returns hash where each key value has form
    # PortID:
    #  port: PORT
    #  matched: false
    def self.get_ndx_existing_ports(port_mh,link_defs_info,opts={})
      ndx_existing_ports = {}
      nodes = link_defs_info.map{|ld|ld[:node]}
      return ndx_existing_ports if nodes.empty?

      # make sure duplicate ports are pruned; tried to use :duplicate_refs => :prune_duplicates but bug; so explicitly looking for existing ports
      sp_hash = {
        cols: ([:node_node_id,:ref,:node] + (opts[:returning_sql_cols]||[])).uniq,
        filter: [:oneof, :node_node_id, nodes.map{|n|n[:id]}]
      }

      Model.get_objs(port_mh,sp_hash,keep_ref_cols: true).each do |r|
        (ndx_existing_ports[r[:node_node_id]] ||= {})[r[:ref]] = {port: r,matched: false}
      end
      ndx_existing_ports
    end
  end
end;end
