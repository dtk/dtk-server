module DTK
  class Clone; class CopyProcessor; class Assembly
    class ServiceAddOnProc
      def initialize(service_add_on_info)
        @service_add_on = service_add_on_info[:service_add_on]
        @node_bindings = service_add_on_info[:service_add_on].get_service_node_bindings()
        @base_assembly = service_add_on_info[:base_assembly]
      end
      attr_reader :node_bindings
      
      def get_mapped_nodes(create_override_attrs,create_opts)
        ret = Array.new
        cols_needed = (create_opts[:returning_sql_cols]||[]) - create_override_attrs.keys
        unless missing = (cols_needed - [:ancestor_id]).empty?
          raise Error.new("Not implemented: get_mapped_nodes returning cols (#{missing.join(",")})")
        end
        sp_hash = {
          :cols => [:id,:group_id,:ancestor_id],
          :filter => [:and, [:eq,:assembly_id,@base_assembly[:id]],
                      [:oneof,:ancestor_id,@node_bindings.map{|nb|nb[:assembly_node_id]}]]
          
        }
        node_mh = @base_assembly.model_handle(:node)
        ret = Model.get_objs(node_mh,sp_hash)
        ndx_node_bindings = @node_bindings.inject(Hash.new){|h,nb|h.merge(nb[:assembly_node_id] => nb)}
        ret.each do |a|
          mapped_ancestor_id = ndx_node_bindings[a[:ancestor_id]][:sub_assembly_node_id]
          a[:ancestor_id] = mapped_ancestor_id
          a[:node_template_id] = mapped_ancestor_id
        end
        ret
      end

      def get_matching_ports_link_hashes_in_target(new_sub_assembly_idh)
        ret = Array.new
        port_links = @service_add_on.get_port_links()
        if port_links.empty?
          return ret
        end
        all_port_ids = port_links.map{|pl|[pl[:input_id],pl[:output_id]]}.flatten
        ndx_assembly_idhs = {:sub_assembly_idh => new_sub_assembly_idh,:assembly_idh => @base_assembly.id_handle()}
        nodes = DTK::Assembly::Instance.get_nodes(ndx_assembly_idhs.values)
        sp_hash = {
          :cols => [:id,:group_id,:display_name,:node_node_id,:ancestor_id],
          :filter => [:and,[:oneof, :ancestor_id, all_port_ids],[:oneof, :node_node_id, nodes.map{|n|n[:id]}]]
        }
        port_mh = @base_assembly.model_handle(:port)
        ndx_target_ports = Model.get_objs(port_mh,sp_hash).inject(Hash.new) do |h,p|
          h.merge(p[:ancestor_id] => p)
        end
        port_links.each do |pl|
          target_in_port = ndx_target_ports[pl[:input_id]]
          check_port(target_in_port,pl[:input_id],:input)
          target_out_port = ndx_target_ports[pl[:output_id]]
          check_port(target_out_port,pl[:output_id],:output)
          ret << pl.hash_subset(:output_is_local,:required).merge(:input_id => target_in_port[:id], :output_id => target_out_port[:id])
        end
        ret
      end
     private
      def check_port(target_port,port_id,dir)
        unless target_port
          Log.error("cannot find match for service add on port #{dir} input port with id (#{port_id})")
        end
      end
    end
  end; end; end
end
    
